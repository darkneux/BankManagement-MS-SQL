--UML Diagram

//www.plantuml.com/plantuml/png/lLLTQzim57tFhn1vQiSARI5ZxAcgdL8FnvXM7knHYqKgPad6aXbXsN-VurWVLYtJ4RgyvPohUy-vzqg-ametgcNLWd15rHui2qcQLEmebqk09IXIy7i1kjy7qAD93Bw094Ckbc56EZJx1f-YH_XqiRg-7EWSI_bBDEKZbYzTH1TmdsJmwVl5xUgJZada0ssawZDrCVU9pls0QKNA7eTA4LOhEQgTo5HiVv9oT2Z5KZa7Eow6Q8sIpNe8A7ZLdKAKaTTSr12iI0dLnB6wV4tzMOpQDdJCDEo8JVNBmthxVWzlJGytj2mh4kPJ73vzbYLObWsHafniGMDhmAqB5qqf7ojPhOoKBgjBtLmRbSyAAnBWSY4LhY9HXXoAbgicbDcTmVajoLy49rdBVkXXvvbfY-7yWYupKhbw7v5hXcbrahSswdhGrh3OV-bRJ6hSADRzFUcAZIxBc6e-OPVRgXpxhIkn9sImlCbDSirugNrlyp8atN6igE21Ji4T6PtuAYYFiTBFo_dDWzljSSNHljPN4Hc7blDCkip4--pcZrgf1DCR7PdS6f_lthoAysqFbgF8zpojmRzcxajnZolCj_rWrb6oWUd5pUUFuFRoFLsW1dE9jyVzEJvohNvEqRFnyoh4gtu2mqFqwzX5GMYgY6jmcdrxhQ7EL9df-SmN3h2Xpa1sJ1cQfpsjxwCtkvZ8RKFhOu3_oPfOHFk5XuM_YtDNnCtKbbIbOdVAafeiFVwMQsQbsi6uIpBD8Sg8L9ZL_zo28WM7mzNLuG2AZbxUB1T53uW3W3q0b00Cyxr3v5c8MGU9JMuejqRaebsG5XExE4H6KXHv5Jf4ayYZa4w6djri5aOEx2Q2HSZ639Dwp1tXPSkglm00



--CREATE USER
EXEC spInsertOrUpdateUser
    @Role = 'Admin',
    @FirstName = 'Sohan',
     @MiddleName = 'Kumar',
    @LastName = 'Lal',
   @AddressLine = '789 New delhi road',
    @City = 'New Delhi',
    @State = 'Delhi',
     @PostalCode = '110001',
     @Country = 'India',
     @PhoneNumber = '999-1234567',
     @Email = 'sohan.lal@itt.com',
   @Designation = 'Branch manager',
    @Age = 40,
    @JoinDate = '2024-03-01';


EXEC spInsertOrUpdateUser
    @Role = 'Customer',
    @FirstName = 'Vivek',
     @MiddleName = 'Kumar',
     @LastName = 'Tiwari',
   @AddressLine = '456 Lucknow Street',
    @City = 'Lucknow',
     @State = 'Uttar Pradesh',
    @PostalCode = '226001',
     @Country = 'India',
    @PhoneNumber = '998-7654321',
    @Email = 'vivek.tiwari@itt.com'


EXEC spInsertOrUpdateUser
    @Role = 'Customer',
    @FirstName = 'Rtik',
   @LastName = 'Dave',
    @AddressLine = '456 Lucknow Street',
     @City = 'Lucknow',
    @State = 'Uttar Pradesh',
    @PostalCode = '226001',
     @Country = 'India',
    @PhoneNumber = '998-7652321',
    @Email = 'ritik.dave@itt.com'



--USERS
exec spLogin 'USER_EE9047_96419' , 'USER@PASS_EE9047_96419' --admin    --ACC12340
exec spLogin 'USER_741EF9_40394' , 'USER@PASS_741EF9_40394' --user1   --ACC12346  --ACC12347
exec spLogin 'USER_B65691_56209' , 'USER@PASS_B65691_56209' --user2     --ACC12345  --ACC12347



--GET ACCOUNT INFO


exec GetAccountInfo 'ACC12346'

--GET TRANSACTION INFO

exec GetTransactions 'ACC12346'

--CREATE ACCOUNT FOR USERS


EXEC CreateAccountForUser @AccountNumber = 'ACC12346', @AccountType = 'Current', @InitialBalance = 100000.00, @UserIDs = '2'


---TransferMoney

EXEC TransferMoney 'ACC12346', 'ACC12345', 100

-- CreditMoney

EXEC CreditMoney 'ACC12346' , 100


-- DebitMoney

EXEC DebitMoney  'ACC12346' , 100




-- GET ALLACCOUNT RELATED INFO


exec spGetAllAccountInformation 2;


--CURRENT USER
select * from ##CurrentSessionUser





----

select * from Customers
select * from Employees
select * from Accounts
select * from AccountUsers
select * from AuditLog
select * from Transactions
select * from UserLogins;

--update UserLogins set IsLocked= 0 , FailedLoginAttempts = 0 ;
