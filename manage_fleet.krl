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
  attributes = {}
  name = "vehicle" + ent:index.as(str);
                          .put(["Prototype_rids"],<child_sub rid as a string>) // ; separated rulesets the child needs installed at creation
                          .put([name],child) // name for child
                          ;
}
{
  event:send({"cid":meta:eci()}, "wrangler", "child_creation")  // wrangler api event.
  with attrs = attributes.klog("attributes: "); // needs a name attribute for child
}
always{
  log("create child for " + child);
}
}

// Request Subscription
rule requestSubscription { // ruleset for parent
 select when subscriptions child_well_known_created well_known re#(.*)# setting (sibling_well_known_eci)
         and subscriptions child_well_known_created well_known re#(.*)# setting (child_well_known_eci)
pre {
   attributes = {}.put(["name"],"brothers")
                   .put(["name_space"],"Tutorial_Subscriptions")
                   .put(["my_role"],"BrotherB")
                   .put(["your_role"],"BrotherA")
                   .put(["target_eci"],child_well_known_eci.klog("target Eci: "))
                   .put(["channel_type"],"Pico_Tutorial")
                   .put(["attrs"],"success")
                   ;
 }
 {
     event:send({"cid":sibling_well_known_eci.klog("sibling_well_known_eci: ")}, "wrangler", "subscription")
         with attrs = attributes.klog("attributes for subscription: ");
 }
 always{
   log("send child well known " +sibling_well_known_eci+ "subscription event for child well known "+child_well_known_eci);
 }
}



}
