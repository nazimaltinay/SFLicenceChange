# Motivation
I need to change licences from Force.com to Lightning Platform nowadays. We can not clone profiles which has different license types as you know.
Object and field basis access rights one of the big headache. 

It provides synchronization of object and field access rights between profiles.


## How to use it.

It is Invocable class and you can call directly from apex class or from Developer Console as Anonymous.

The sample call prototype is in following;

        List<SFProfileHandler.InputParameter> Params = new List<SFProfileHandler.InputParameter>();
        SFProfileHandler.InputParameter param = new SFProfileHandler.InputParameter();
        param.ProfileFrom = 'Profile NAME from';
        param.ProfileTo =   'to New Profile Name';  
        params.add(param);
        SFProfileHandler.CloneProfilePermissions(Params);

## Next developmets.
    - It can be a LWC to call from page
    - Object name filter can be added.