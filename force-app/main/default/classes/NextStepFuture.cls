/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */
public with sharing class NextStepFuture {

    /* 
     * Question 1
     * Update/Uncomment the template code to create a method
     * Create a future method that updates all account and opportunities next step to 'Meeting in the future'
     * Account Next Step field is a custom field
     * Opportunity Next Step field is a standard field
     * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testUpdateAllNextStep to cover test this method
     */
    @future
    public static void updateNextStepFields (Set<Id> accountIds) {
        if(accountIds == null) {
        }
        if(accountIds != null) {
            List<Account> accounts = [SELECT Id, Next_Step__c, (SELECT Id, AccountId, NextStep FROM Opportunities) FROM Account WHERE Id IN :accountIds];

            Map<Id,List<Opportunity>> accountIdsAndOpps = new Map<Id,List<Opportunity>>();

            for(Account a : accounts) {
                if(!accountIdsAndOpps.containsKey(a.Id)) {
                    accountIdsAndOpps.put(a.Id, a.Opportunities);
                }
            }
            
            List<Opportunity> opps = new List<Opportunity>();

            for(List<Opportunity> oppList : accountIdsAndOpps.values()) {
                opps.addAll(oppList);
            }

            for(Opportunity o : opps) {
                o.NextStep = 'Meeting in the future';
            }

            for(Account a : accounts) {
                a.Next_Step__c = 'Meeting in the future';
            }

        update accounts;
        update opps;
        }
    }

    /*
    * Question 2
    * Update/Uncomment the template code to create a method
    * Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
    * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testCreateDealAndUpdateRole to cover test this method
    */
    //Mix DML Error happens when you try to perform DML operations on setup and non-setup objects in a single transaction.
    public static void createDealAndUpdateRole() {
        // NM - bigDeal is the variable that will hold the values of the Opp that is about to be created
        Opportunity bigDeal = new Opportunity();

        // NM - insertBigDeal calls the method that actually creates the Opp
        insertBigDeal(bigDeal);

        // NM - to prevent mixed DML, create and call a future method that calls updateUserRoleName

        // UserRole[] roles = [SELECT Id, Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() OR Name = 'CRO' LIMIT 1];
        List<User> users = new List<User>([SELECT Id, UserRoleId FROM User WHERE Id = :bigDeal.OwnerId]);
        List<Id> roleIds = new List<Id>();
        for(User user : users) {
            roleIds.add(user.UserRoleId);
        }
        updateUserRoleName(roleIds);
    }

    // Helper method to insert big deal
    private static void insertBigDeal(Opportunity opp) {
        opp.Amount = 1000000;
        opp.Name = 'Big Deal';
        opp.StageName = 'Closed Won'; 
        opp.CloseDate = Date.today();
        
        insert opp;
    }


    // Helper method to update role name
    // NM - does updateUserRoleName need to be reworked to be a future method that can be called from createDealAndUpdateRole
    // NM - alternative, create future method to call updateUserRoleName as-is to avoid changing parameter?
    @future
    private static void updateUserRoleName(List<Id> roleIds){
        List<User> userRoles = [SELECT Id, UserRoleId FROM User WHERE UserRoleId IN :roleIds];
        UserRole role;
        if (userRoles.isEmpty()) {
            role = new UserRole();
            role.portalType = 'None'; 
            role.CaseAccessForAccountOwner = 'Edit'; 
            // role.OpportunityAccessForAccountOwner = 'Edit'; //This may need to be uncommented depending on your orgs Organization Wide Defaults(OWD) settings. If you are receiving FIELD_INTEGRITY_EXCEPTION, field integrity exception: unknown (Opportunity access level below organization default): [unknown], uncomment this line.
        } else {
            for(User user : userRoles) {
                role = userRoles[0].UserRole;
            }
        }

        role.Name = 'CRO';

        upsert role;
    }
}