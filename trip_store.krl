ruleset hello_world {
  meta {
    name "trip_store"
    author "Isaac Hartung"
    logging on
    sharing on
      provides trips, long_trips, short_trips
 
  }


  global {


    trips = function(){
      trips = ent:trips;
      trips
    };

    long_trips = function(){
      long_trips = ent:long_trips;
      long_trips
    };

    short_trips = function(){
      all_trips = trips();
      all_long_trips = long_trips();
      skeys = all_trips.keys().klog("keys from trips: ");
      keys = all_long_trips.keys().klog("keys from long: ");
      short_trips = alltrips.filter( function(t_l, zeit){
        (not keys.any(function(x){t_l eq x}));
      }).klog("short_trips: ");

      short_trips

    };

  }

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


}