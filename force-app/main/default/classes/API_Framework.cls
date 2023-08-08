public without sharing class API_Framework {
    
    @InvocableMethod
    public static List<List<String>> callApi(List<List<String>> idList){
        List<List<String>> returnList = new List<List<String>>();
        List<String> errorList = new List<String>();
        String queryString = '';
        
        List<String> queryId = idList.get(0);
        String apiId = queryId.get(0);
        String objectId = queryId.get(1);
        
        List<API__c> apiList = [SELECT Id, Name, Object_Name__c, Credential__c, HTTP_Method__c, HTTP_Content_Type__c
                                FROM API__c WHERE Id = :apiId LIMIT 1];
        
        if (apiList.size() < 1){
            errorList.add('No API.');
            logAPIRequest(queryId.get(0), '- no data -', '-0', 'No API.', 'Open', 'API_Framework', '-no data-', '-no data-');
            
            returnList.add(errorList);
        }
        else{
            
            API__c api = apiList[0];
            
            switch on api.Object_Name__c {
                when 'Account' {
                    queryString = 'SELECT Id, Name FROM Account';
                }	
                when 'Opportunity' {
                    queryString = 'SELECT Id, Name FROM Opportunity';
                }
                when 'Brand__c' {
                    queryString = 'SELECT Id, Name FROM Brand__c';
                }
                when else {
                    logAPIRequest(api.Id, '- no data -', '-0', 'No Object in API.', 'Open', 'API_Framework', '-no data-', api.HTTP_Method__c);
                }
            }
            
            List <sObject> slist  = Database.query(queryString);
            
            outboundRestCall(api.Id, api.Credential__c, api.HTTP_Method__c, api.HTTP_Content_Type__c, null);
            
            returnList = null;
        }
        
        return returnList;
        
    }
    
    @future(callout=true)
    public static void outboundRestCall(Id apiId, String credential, String method, String contentType, String body){
        try{
            Http httpInstance = new Http();
            HttpRequest request = new HttpRequest();
            HttpResponse response;
            
            String endpoint = 'callout:' + credential;
            
            request.setEndpoint(endpoint);
            
            request.setMethod(method);
            request.setHeader('Content-Type', contentType);
            if(method == 'POST' || method == 'PUT'){
                request.setBody(body);
            }
            
            response = httpInstance.send(request);
            
            if (response.getStatusCode() == 201 || response.getStatusCode() == 200) {
                //Map<String, Object> responseList = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

                logAPIRequest(apiId, String.valueOf(request), String.valueOf(response.getStatusCode()), response.getBody(), 'Closed', 'API_Framework', 'id : ', method);
            }
            else {
                // Handle the error
                logAPIRequest(apiId, String.valueOf(request), String.valueOf(response.getStatusCode()), response.getBody(), 'Open', 'API_Framework', 'id : ', method);
            }
        } catch (DmlException e) {
            logAPIRequest(apiId, '', '-5', e.getMessage(), 'Open', 'API_Framework', 'id : ', method);
        }
    }
    
    // Log API Request
    // 
    // Create a Log_API object, that 
    // Values:
    // 
    // apiId - 
    // inputMsg -
    // retCode -
    // outputMsg -
    // status - 
    // apexClass - 
    // objectID -
    // httpMethod - 
    //
    public static void logAPIRequest(Id apiId, String inputMsg, String retCode, String outputMsg, String status, String apexClass, String objectId, String httpMethod){
        Log_API__c log = new Log_API__c();
        
        List<API__c> apiList = [SELECT Id, Name, Credential__c, HTTP_Method__c, HTTP_Content_Type__c, RecordType.Name
                                FROM API__c WHERE Id = :apiId LIMIT 1];
        
        if (apiList.size() == 1){
            API__c api = apiList[0];
            log.API_Record_Type__c = api.RecordType.Name;
        }
        
        log.API__C = apiId;
        log.Input_Body__c = inputMsg;
        log.Return_Code__c = retCode;
        log.Output_Body__c = outputMsg;
        log.Status__c = status;
        log.Apex_Class__c = apexClass;
        log.Object_ID__c = objectId;
        log.HTTP_Method__c = httpMethod;
        
        insert log;
    }
    
}