ruleset track-trips {
  meta {
    name "track_trips"
    author "Isaac Hartung"
    logging on
    sharing on
      provides hello

  }


  global {

    hello = function(obj) {
      msg = "Hello " + obj
      msg
    };

  }

  rule message {
    select when echo message
    pre{
      mileage = event:attr("input").klog("mileage: ");
      }
      {

        send_directive("say") with
        something = input;
      }
      }



  rule process_trip {
    select when car new_trip
    pre{
      mileage = event:attr("mileage").klog("mileage: ");

      atts = {
          "mileage" : mileage
      };

      }
      {
        send_directive("say") with
        trip_length = mileage;

      }
      always{
      raise explicit event 'trip_processed' // common bug to not put in ''.
          attributes atts;
       log "raising explicit:trip_processed with mileage=" + mileage;
       }

  }

  rule find_long_trips {

    select when explicit trip_processed
    pre{


      m = event:attr("mileage").klog("pass in mileage: ");
      mileage = m.decode().klog("mileage decoded: ");

    }
    if(mileage > ent:long_trip) then {
      send_directive("found") with
        trip_length = mileage;
    }
    fired {

      raise explicit event 'trip_processed' // common bug to not put in ''.
          attributes {};
       set ent:long_trip mileage;
       log "raising explicit:found_long_trip with mileage=" + m;
       //log "action: " + m + " > " + ent:long_trip;

    }
    else {
      log "no action: " + m + " <= " + ent:long_trip;
    }

  }


}
