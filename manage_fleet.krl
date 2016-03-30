ruleset manage_fleet {
  meta {
    name "manage_fleet"
    author "Isaac Hartung"
    logging on
    sharing on


    use module  b507199x5 alias wranglerOS
    provides vehicles, report



  }


  global {


  r = function(){

  (ent:report == 0) => [] |
                    ent:report

  };


    ids = function() {

      (ent:ids == 0) => [] |
                        ent:ids


    };


    call_trips = function(eci) {


        cloud_url = "https://#{meta:host()}/sky/cloud/";
        logger = cloud_url.klog("cloud_url: ");

          cloud = function(eci, mod, func, params) {
          x = "#{cloud_url}#{mod}/#{func}".klog("url: ");
          response = http:get("#{cloud_url}#{mod}/#{func}", (params || {}).put(["_eci"], eci));


          status = response{"status_code"};


          error_info = {
              "error": "sky cloud request was unsuccesful.",
              "httpStatus": {
                  "code": status,
                  "message": response{"status_line"}
              }
          };


          response_content = response{"content"}.decode();
          response_error = (response_content.typeof() eq "hash" && response_content{"error"}) => response_content{"error"} | 0;
          response_error_str = (response_content.typeof() eq "hash" && response_content{"error_str"}) => response_content{"error_str"} | 0;
          error = error_info.put({"skyCloudError": response_error, "skyCloudErrorMsg": response_error_str, "skyCloudReturnValue": response_content});
          is_bad_response = (response_content.isnull() || response_content eq "null" || response_error || response_error_str);


          // if HTTP status was OK & the response was not null and there were no errors...
          (status eq "200" && not is_bad_response) => response_content | error
      };

      cloud(eci, "b507740x2.prod", "trips", null)


    };


//-------------------------------vehicles-------------------------------------

    vehicles = function() {
      vehicles = wranglerOS:children();
      vs = vehicles{"children"}.klog("list of vehicles ");
      vs
    };

//-------------------------------report-------------------------------------

    report = function() {

      vehicles = vehicles().klog("children picos: ");
      report = vehicles.map(function(x) {call_trips(x[0])}).klog("report: ");
      report

    };
    }


//-------------------------------create_vehicle------------------------------

  rule create_vehicle {
    select when car new_vehicle
    pre{
    val = ent:counter;
    //ids = ids();
    name = "vehicle" + val.as(str);
    val = val + 1;
    attributes = {}

                          .put(["Prototype_rids"],"b507740x2.prod") // ; separated rulesets the child needs installed at creation
                          .put(["name"],name) // name for child
                          ;
}
{

send_directive("vehicle_created") with
  name = name;

  event:send({"cid":meta:eci()}, "wrangler", "child_creation")  // wrangler api event.
  with attrs = attributes.klog("attributes: "); // needs a name attribute for child



}
always{
  log "create child for " + name;
  //set ent:ids ids().append(name);
  set ent:counter val;
}
}


//-------------------------------delete_vehicle------------------------------

rule delete_vehicle {
  select when car unneeded_vehicle
  pre {
    delete_id = event:attr("vehicle").klog("pass in mileage: ");
  }
  if(ent:report.length() eq children.length()) then {
    send_directive("Finished Report") with
      report = ent:report;
  }
  fired {

    log "Sent the following report: " + ent:report;
     clear ent:report;


  }
  else {
    log "partial report: " + ent:report;
  }

}

//-------------------------------request_sub------------------------------

// Request Subscription
//rule requestSubscription { // ruleset for parent
// select when subscriptions child_well_known_created well_known re#(.*)# setting (sibling_well_known_eci)
//pre {
//   my_eci = meta:eci();
//   attributes = {}.put(["name"],"brothers")
//                   .put(["name_space"],"Tutorial_Subscriptions")
//                   .put(["my_role"],"BrotherB")
//                   .put(["your_role"],"BrotherA")
//                   .put(["target_eci"],my_eci.klog("target Eci: "))
//                   .put(["channel_type"],"Pico_Tutorial")
//                   .put(["attrs"],"success")
//                   ;
//
//
// }
// {
//     event:send({"cid":sibling_well_known_eci.klog("sibling_well_known_eci: ")}, "wrangler", "subscription")
//         with attrs = attributes.klog("attributes for subscription: ");
// }
// always{
//   log("send child well known " +sibling_well_known_eci+ "subscription event for child well known "+my_eci);
// }
//}

//-------------------------------receive_report-------------------------------------

rule receive_report {
  select when report complete
  pre{
    id = event:attr("id").klog("pass in id: ");
    trips = event:attr("trips").klog("pass in trips: ");
    element = {}.put([id], trips);



  }
  {
    send_directive("received") with
    report = trips;

  }
  always{
    log "received report from : " + id;
    set ent:report r().append(element).klog("current report: ");
    raise report event 'check' // common bug to not put in ''.
        attributes {};

  }

}

rule check_report {
  select when report check
  pre{
    report = {}.put(["vehicles"], ent:ids.length())
                .put(["trips"], ent:report);


  }
  if(ent:report.length() eq ent:ids.length()) then {
    send_directive("Finished Report") with
      report = report;
  }
  fired {

    log "Sent the following report: " + report;
     clear ent:report;
     clear ent:temp;


  }
  else {
    log "partial report: " + ent:report;
  }

}



rule send_request {
  select when report request
    foreach vehicles() setting (child)
    pre{
      val = ent:temp;
      attributes = {}.put(["id"], ent:ids[val]);
      val = val + 1;

    }
    {
      send_directive("sent_request") with
      report = child[0].klog("eci: ");

      event:send({"cid":child[0]}, "fleet", "report")
      with attrs = attributes.klog("attributes: ");

    }
    always{

      log "Sent a request to " + child;
      set ent:temp val;


    }

}



}
