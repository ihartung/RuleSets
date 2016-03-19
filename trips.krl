ruleset hello_world {
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


  rule process_trip {
    select when echo message
    pre{
      mileage = event:attr("mileage").klog("mileage: ");
      }
      {
      
        send_directive("say") with
        trip_length = mileage;
      }

  }


}