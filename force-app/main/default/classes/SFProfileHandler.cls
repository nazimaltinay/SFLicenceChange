public with sharing class SFProfileHandler {
    

    @invocableMethod(label = 'Clone Profile Permissions' description='Profile From, Profile To' category='Profile' )
    public static List<Boolean>   CloneProfilePermissions(List<InputParameter> Params)
    {
        List<Boolean> results = new List<Boolean>();
        
        SFProfileHandler sfP=  new  SFProfileHandler();

        for(InputParameter inP: Params)
        {
            sfP.profileFromName = inp.ProfileFrom;
            sfP.ProfileToName = inp.ProfileTo;
        }

        //sfP.profileFromName = 'Test Planning Production';
        system.debug('Profile From -->'+ sfp.ProfileFrom );
        system.debug('Permission set from-->'+sfp.PermissionSetFrom );
        //sfP.ProfileToName = 'New Planning Profile';
        system.debug('Profile To -->'+ sfp.ProfileTo );
        system.debug('Permission set from-->'+sfp.PermissionSetTo );
        List<ObjectPermissions > objPerms = sfp.ObjectPermissionsFrom;
        for(ObjectPermissions objP:objPerms )
        {
            //system.debug('objPerm -->'+objP );   
        }
        system.debug('Object Types-->'+ sfp.ObjectTypeNames);
        system.debug('field permissions From-->'+ sfp.fieldPermissionsFrom );
        system.debug('field permissions To-->'+ sfp.fieldPermissionsTo );
        system.debug('ObjectPermissions To-->'+ sfp.objectPermissionsTo );
        sfp.CloneObjectPermissions();
        sfp.CloneFieldPermissions();
        results.add(true);
        return results;
    }

    public  class InputParameter {
        @InvocableVariable(Label='Profile From'  required=true )
        public String ProfileFrom;
        @InvocableVariable(Label='Profile To'  required=true )
        public String ProfileTo;
    }

    private class localException extends Exception{}
    // will be used to prevent duplicates.    
    private Map<String,  FieldPermissions> fieldNames {get; private set;}
    private Map<String, ObjectPermissions> objectNames {get; private set;}

    public String profileFromName {get; set; }
    public String profileToName {get; set;}
    public PermissionSet PermissionSetFrom {get; private set;}
    public PermissionSet PermissionSetTo {get; private set;}
    


    public List<FieldPermissions> fieldPermissionsFrom {get
        {
            List<FieldPermissions> flPrms = [SELECT  Id, ParentId, SobjectType, Field, PermissionsEdit, PermissionsRead FROM FieldPermissions where Sobjecttype in : this.ObjectTypeNames and ParentId = : PermissionSetFrom.Id ];
             return flPrms;
        }
        
        private set;
    }
    public List<FieldPermissions> fieldPermissionsTo {get
        {
            List<FieldPermissions> flPrms = [SELECT  Id, ParentId, SobjectType, Field, PermissionsEdit, PermissionsRead FROM FieldPermissions where Sobjecttype in : this.ObjectTypeNames and ParentId = : PermissionSetTo.Id ];
            this.fieldNames = new Map<String, FieldPermissions>(); 
            for(FieldPermissions fldP : flPrms){
                fieldNames.put(fldP.ParentId+ fldP.Field, fldP);
                //System.debug('Map Value -->'+i+' : ' +  fldP.ParentId+ fldP.Field );
            }
            
            return flPrms;
        }
        private set;
    }    

    public Profile profileFrom {
        get{
            List<Profile> prof= [ SELECT UserLicenseId, Id, Name FROM Profile where Name =:profileFromName];
            if(prof.size()>0) 
            {
                this.PermissionSetFrom = [SELECT Id, Name, Label, LicenseId, ProfileId FROM PermissionSet where ProfileId =:prof[0].Id];


                return prof[0];
            } else {
                throw new localException ('Error: User profile could not be found. Check profile From Name ' );
            }
        }
    }
    public Profile profileTo {
        get{
            List<Profile> prof= [ SELECT UserLicenseId, Id, Name FROM Profile where Name =:profileToName];
            if(prof.size()>0) 
            {
                this.PermissionSetTo = [SELECT Id, Name, Label, LicenseId, ProfileId FROM PermissionSet where ProfileId =:prof[0].Id];
                return prof[0];
            } else {
                throw new localException ('Error: User profile could not be found. Check profile To Name ' );
            }
        }
    }

    public List<String> ObjectTypeNames{get; private set;}
    
    public   List<ObjectPermissions > objectPermissionsFrom 
    {
        get{
            this.ObjectTypeNames = new List<String>();

            List<ObjectPermissions > objPerms= [
                SELECT ParentId, sObjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete, PermissionsModifyAllRecords, 
                    PermissionsViewAllRecords FROM ObjectPermissions 
                 WHERE ParentId IN ( SELECT Id 
                        FROM permissionset 
                       WHERE PermissionSet.Profile.Name = :profileFromName ) and PermissionsRead = true 
                    ];
            for(ObjectPermissions objP:objPerms )
            {
                this.ObjectTypeNames.add(objP.sObjectType);   
            }
            return objPerms;
        }
    }
    public   List<ObjectPermissions > objectPermissionsTo
    {
        get{

            List<ObjectPermissions> objPerms= [
                SELECT ParentId, sObjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete, PermissionsModifyAllRecords, 
                    PermissionsViewAllRecords FROM ObjectPermissions 
                 WHERE ParentId IN ( SELECT Id 
                        FROM permissionset 
                       WHERE PermissionSet.Profile.Name = :profileToName ) and PermissionsRead = true 
                    ];
            
           this.ObjectNames = new Map<String, ObjectPermissions>();     
           for(ObjectPermissions objP : objPerms){
                ObjectNames.put(objP.sObjectType, objP);
            }
            return objPerms;
        }
    }
    /*
        Warning !!! you need to be sure parameter must be adjusted before call the Clone class
    */

    public Boolean CloneFieldPermissions()
    {
        List<FieldPermissions> newFieldPermissions = new List<FieldPermissions>();
        for(FieldPermissions fldp:fieldPermissionsFrom)
        {
            if( ! fieldNames.containsKey(this.PermissionSetTo.Id+fldp.Field)    )
            {
                newFieldPermissions.add(
                    new FieldPermissions(
                        Field = fldp.Field,
                        SObjectType = fldp.SobjectType,
                        ParentId =  this.PermissionSetTo.Id,
                        PermissionsRead = fldp.PermissionsRead,
                        PermissionsEdit = fldp.PermissionsEdit
                    ));
            } else {
                FieldPermissions fPrm =  fieldNames.get(this.PermissionSetTo.Id+fldp.Field);
                fPrm.PermissionsRead = fldp.PermissionsRead;
                fPrm.PermissionsEdit = fldp.PermissionsEdit;
                newFieldPermissions.add(fPrm);
            }
        }
        System.debug('fieldPErmission count--->'+ newFieldPermissions.size() + ' / TOTAL fieldPErmission count--->'+ fieldPermissionsFrom.size());
        Integer errC = 0;
        Database.UpsertResult[] srList =  Database.upsert(newFieldPermissions, false);
        for (Database.UpsertResult sr : srList) {
            if (!sr.isSuccess()) {
                 // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error -->#'+errC+': '+ err.getStatusCode() + ': ' + err.getMessage()+' Affected fields:'+err.getFields() );
                }
                errC++;
            }
        }        
        return true;
    }
    public Boolean CloneObjectPermissions()
    {
        List<ObjectPermissions> objPermsNew = new List<objectPermissions>();
        List<ObjectPermissions> objPermsUpd= new List<objectPermissions>();
        for(ObjectPermissions Objp:objectPermissionsFrom)
        {
            if( ! objectNames.containsKey( Objp.SobjectType)    )
            {
                objPermsNew.add(
                new ObjectPermissions(
                        SobjectType = objP.SobjectType,
                        ParentId=this.PermissionSetTo.Id,
                        PermissionsCreate= objP.PermissionsCreate,
                        PermissionsRead = objP.PermissionsRead,
                        PermissionsEdit = objP.PermissionsEdit,
                        PermissionsDelete = objP.PermissionsDelete,
                        PermissionsViewAllRecords = objP.PermissionsViewAllRecords,
                        PermissionsModifyAllRecords = objP.PermissionsModifyAllRecords
                    )
                );
            } else {
            
                ObjectPermissions objEx =  objectNames.get(objP.SobjectType);
                objEx.PermissionsCreate= objP.PermissionsCreate;
                objEx.PermissionsRead = objP.PermissionsRead;
                objEx.PermissionsEdit = objP.PermissionsEdit;
                objEx.PermissionsDelete = objP.PermissionsDelete;
                objEx.PermissionsViewAllRecords = objP.PermissionsViewAllRecords;
                objEx.PermissionsModifyAllRecords = objP.PermissionsModifyAllRecords;
                objPermsNew.add(objEx);
            }
          }
          Database.UpsertResult[] srList =   Database.upsert(objPermsNew, false);
          Integer errC =0;
          for (Database.UpsertResult sr : srList) {
            if (!sr.isSuccess()) {
                 // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error -->#'+errC+': ' + err.getStatusCode() + ': ' + err.getMessage()+' Affected fields:'+err.getFields() );
                }
            }
            errC++;
        }

         System.debug('Object Permission count--->'+ objPermsNew.size());
        return true;
    }


}