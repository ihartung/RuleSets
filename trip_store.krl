ruleset trip_store {
  meta {
    name "trip_store"
    author "Isaac Hartung"
    logging on
    sharing on
      provides trips, long_trips, short_trips

  }


  global {




  //----------------------------trips----------------------------------

    trips = function(){
      trips = ent:trips;
      trips
    };


    //----------------------------long_trips----------------------------------

    long_trips = function(){
      long_trips = ent:long_trips;
      long_trips
    };


    //----------------------------short_trips----------------------------------

    short_trips = function(){
      all_trips = trips();
      all_long_trips = long_trips();
      skeys = all_trips.keys().klog("keys from trips: ");
      keys = all_long_trips.keys().klog("keys from long: ");

      checker = function(distance){
        keys.any(function(x){distance eq x}) => false | true
      };

      bool = checker("55").klog("is 55 cc in there: ");
      bool2 = checker("77").klog("is 77 cc in there: ");




      short_trips = all_trips.filter( function(t_l, zeit){
        checker(t_l).klog("is it in long? ");
      }).klog("short_trips: ");

      short_trips

    };

  }



  //----------------------------collect_trips----------------------------------

  rule collect_trips {
    select when explicit trip_processed
      pre{
        m = event:attr("mileage").klog("pass in mileage: ");
        t = time:now();
        new_trip = {
              "when" : t,
              "trip_length" : m
        }
      }
      {
        send_directive("trip") with
          trip = m and
          time = t;
      }
      always{
        set ent:trips{[m]} t;
      }


  }



  //----------------------------Collect_long_trips----------------------------------

  rule collect_long_trips{
    select when explicit found_long_trip
    pre{
      m = event:attr("mileage").klog("pass in mileage: ");
      t = time:now();
      }
      {
      send_directive("long_trip") with
        long_trip = m and
        time = t;
      }
      always{
        set ent:long_trips{[m]} t;
      }


  }



  //----------------------------clear_trips----------------------------------

  rule clear_trips {
    select when car trip_reset
    {
      send_directive("cleared");
    }
    always{
      clear ent:trips;
      clear ent:long_trips;
    }
  }



  //----------------------------createWellKnown----------------------------------

//rule createWellKnown {
//    select when wrangler init_events
//    pre {
//      attr = {}.put(["channel_name"],"Well_Known")
//                      .put(["channel_type"],"Pico_Tutorial")
//                      .put(["attributes"],"")
//                      .put(["policy"],"")
//                      ;
//    }
//    {
//        event:send({"cid": meta:eci()}, "wrangler", "channel_creation_requested")
//        with attrs = attr.klog("attributes: ");
//    }
//    always {
//      log("created wellknown channel");
//    }
//  }

//----------------------------WellKnownCreated----------------------------------

//rule wellKnownCreated {
//    select when wrangler channel_created where channel_name eq "Well_Known" && channel_type eq "Pico_Tutorial"
//    pre {
//        // find parent
//        parent_results = wrangler_api:parent();
//        parent = parent_results{'parent'};
//        parent_eci = parent[0].klog("parent eci: ");
//        well_known = wrangler_api:channel("Well_Known").klog("well known: ");
//        well_known_eci = well_known{"cid"};
//        init_attributes = event:attrs();
//        attributes = init_attributes.put(["well_known"],well_known_eci);
//    }
//    {
//        event:send({"cid":parent_eci.klog("parent_eci: ")}, "subscriptions", "child_well_known_created")
//            with attrs = attributes.klog("event:send attrs: ");
//    }
//    always {
//      log("parent notified of well known channel");
//    }
//  }


  //----------------------------send_report----------------------------------

  rule send_report {
    select when fleet report
    pre {

      id = event:attr("id").klog("pass in id: ");
      trips = ent:trips;
      parent_results = wrangler_api:parent();
      parent = parent_results{'parent'};
      parent_eci = parent[0].klog("parent eci: ");
      attributes = init_attributes.put(["trips"],trips)
                                  .put(["id"],id);
    }
    {
      send_directive("report") with
      report = attributes;

      event:send({"cid":parent_eci}, "report", "complete")
               with attrs = attributes.klog("event:send attrs: ");

    }
    always{
      log("parent sent report");
    }



  }

}
