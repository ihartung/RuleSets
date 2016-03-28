ruleset manage_fleet {
  meta {
    name "manage_fleet"
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

  rule create_vehicle {
    select when car new_vehicle
    pre{
      mileage = event:attr("input").klog("mileage: ");
      }
      {

        send_directive("say") with
        something = input;
      }
      }



}
