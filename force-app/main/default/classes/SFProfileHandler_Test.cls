@istest
public with sharing class SFProfileHandler_Test {
    
    @istest static void TestCloneProfile()
    {

        List<SFProfileHandler.InputParameter> Params = new List<SFProfileHandler.InputParameter>();
        SFProfileHandler.InputParameter param = new SFProfileHandler.InputParameter();
        param.ProfileFrom = 'Test Planning Production';
        param.ProfileTo =   'New Planning Profile';  
        params.add(param);
        SFProfileHandler.CloneProfilePermissions(Params);
    }
    
 
}
