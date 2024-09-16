CREATE OR ALTER PROCEDURE spInsertOrUpdateUser
    @Role NVARCHAR(20),
    @FirstName NVARCHAR(20),
    @MiddleName NVARCHAR(20) = NULL,
    @LastName NVARCHAR(20),
    @AddressLine NVARCHAR(255),
    @City NVARCHAR(100),
    @State NVARCHAR(100),
    @PostalCode NVARCHAR(20),
    @Country NVARCHAR(100),
    @PhoneNumber NVARCHAR(15),
    @Email NVARCHAR(100),
    @DepartmentID INT = NULL, -- for employees
    @Designation NVARCHAR(100) = NULL, -- for employees
    @Age INT = NULL, -- for employees
    @JoinDate DATE = NULL -- for employees
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID NVARCHAR(50) = CONCAT(SUBSTRING(CAST(NEWID() AS VARCHAR(50)), 1, 6), '_', CAST(ABS(CHECKSUM(NEWID()) % 100000) AS NVARCHAR(50)));
    DECLARE @LoginName NVARCHAR(50) = CONCAT('USER_', @ID),
            @Password NVARCHAR(255) = CONCAT('USER@PASS_', @ID);

    DECLARE @UserID INT;
    DECLARE @PasswordHash VARBINARY(256) = HASHBYTES('SHA2_256', @Password);

    PRINT 'Login successful. New credentials generated. Login ID: ' + @LoginName + ', Password: ' + @Password;

    --    check user with this email exists or not
    SELECT @UserID = u.UserID
    FROM Users u
    INNER JOIN Emails e ON u.UserID = e.UserID
    WHERE e.Email = @Email;

    IF @Role = 'Employee' OR @Role = 'Admin'
    BEGIN
        IF @UserID IS NULL
        BEGIN
    
            INSERT INTO UserLogins (LoginName, PasswordHash)
            VALUES (@LoginName, @PasswordHash);

            SET @UserID = SCOPE_IDENTITY();

            INSERT INTO Users (LoginID, FirstName, MiddleName, LastName)
            VALUES (@UserID, @FirstName, @MiddleName, @LastName);

            INSERT INTO Employees (UserID, DepartmentID, Designation, Age, JoinDate)
            VALUES (@UserID, @DepartmentID, @Designation, @Age, @JoinDate);
        END
        ELSE
        BEGIN
      
            UPDATE Employees
            SET DepartmentID = @DepartmentID,
                Designation = @Designation,
                Age = @Age,
                JoinDate = @JoinDate,
                UpdatedAt = GETDATE()
            WHERE UserID = @UserID;

 
            UPDATE Users
            SET FirstName = @FirstName,
                MiddleName = @MiddleName,
                LastName = @LastName,
                UpdatedAt = GETDATE()
            WHERE UserID = @UserID;


            UPDATE UserLogins
            SET PasswordHash = @PasswordHash,
                UpdatedAt = GETDATE()
            WHERE LoginID = @UserID;
        END
    END
    ELSE IF @Role = 'Customer'
    BEGIN
        IF @UserID IS NULL
        BEGIN

            INSERT INTO UserLogins (LoginName, PasswordHash)
            VALUES (@LoginName, @PasswordHash);

            SET @UserID = SCOPE_IDENTITY();

            INSERT INTO Users (LoginID, FirstName, MiddleName, LastName)
            VALUES (@UserID, @FirstName, @MiddleName, @LastName);

         
            INSERT INTO Customers (UserID, AccountTypeID)
            VALUES (@UserID, NULL); 
        END
        ELSE
        BEGIN

            UPDATE Customers
            SET UpdatedAt = GETDATE()
            WHERE UserID = @UserID;

       
            UPDATE Users
            SET FirstName = @FirstName,
                MiddleName = @MiddleName,
                LastName = @LastName,
                UpdatedAt = GETDATE()
            WHERE UserID = @UserID;


            UPDATE UserLogins
            SET PasswordHash = @PasswordHash,
                UpdatedAt = GETDATE()
            WHERE LoginID = @UserID;
        END
    END


    IF @AddressLine IS NOT NULL
    BEGIN
        MERGE Addresses AS target
        USING (SELECT @AddressLine AS AddressLine, @City AS City, @State AS State, @PostalCode AS PostalCode, @Country AS Country, @UserID AS UserID) AS source
        ON target.UserID = source.UserID
        WHEN MATCHED THEN
            UPDATE SET AddressLine = source.AddressLine,
                       City = source.City,
                       State = source.State,
                       PostalCode = source.PostalCode,
                       Country = source.Country,
                       UpdatedAt = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (AddressLine, City, State, PostalCode, Country, UserID)
            VALUES (source.AddressLine, source.City, source.State, source.PostalCode, source.Country, source.UserID);
    END

    IF @PhoneNumber IS NOT NULL
    BEGIN
        MERGE PhoneNumbers AS target
        USING (SELECT @PhoneNumber AS PhoneNumber, @UserID AS UserID) AS source
        ON target.UserID = source.UserID
        WHEN MATCHED THEN
            UPDATE SET PhoneNumber = source.PhoneNumber,
                       UpdatedAt = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (PhoneNumber, UserID)
            VALUES (source.PhoneNumber, source.UserID);
    END

    IF @Email IS NOT NULL
    BEGIN
        MERGE Emails AS target
        USING (SELECT @Email AS Email, @UserID AS UserID) AS source
        ON target.UserID = source.UserID
        WHEN MATCHED THEN
            UPDATE SET Email = source.Email,
                       UpdatedAt = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (Email, UserID)
            VALUES (source.Email, source.UserID);
    END
END;


CREATE OR ALTER PROCEDURE spLogin
    @LoginName NVARCHAR(50),
    @Password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT, 
            @StoredPasswordHash VARBINARY(256),
            @IsFirstLogin BIT,
            @FailedAttempts INT, 
            @IsLocked BIT, 
            @UnlockTime DATETIME,
            @PasswordHash VARBINARY(256) = HASHBYTES('SHA2_256', @Password),
            @CurrentRole NVARCHAR(20)

    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        CREATE TABLE ##CurrentSessionUser (
            UserID INT,
            LoginName NVARCHAR(50),
            Role NVARCHAR(20)
        );
    END

    TRUNCATE TABle ##CurrentSessionUser;

    SELECT @UserID = ul.LoginID,
           @StoredPasswordHash = ul.PasswordHash, 
           @IsFirstLogin = ul.IsFirstLogin,
           @FailedAttempts = ul.FailedLoginAttempts,
           @IsLocked = ul.IsLocked,
           @UnlockTime = ul.UnlockTime,
           @CurrentRole = CASE 
                          WHEN EXISTS (SELECT 1 FROM Employees WHERE UserID = ul.LoginID) THEN 'Employee'
                          WHEN EXISTS (SELECT 1 FROM Customers WHERE UserID = ul.LoginID) THEN 'Customer'
                          ELSE 'Admin' END
    FROM UserLogins ul
    WHERE ul.LoginName = @LoginName;

    IF @UserID IS NULL
    BEGIN
        PRINT 'Login Name does not exist.';
        RETURN;
    END

    IF @IsLocked = 1
    BEGIN
        IF @UnlockTime > GETDATE()
        BEGIN
            INSERT INTO AuditLog (UserID, Action, Status, Description)
            VALUES (@UserID, 'Login', 'Locked', 'Account is locked until ' + CONVERT(NVARCHAR, @UnlockTime));
            PRINT 'Account is locked until ' + CONVERT(NVARCHAR, @UnlockTime);
            RETURN;
        END
        ELSE
        BEGIN
            UPDATE UserLogins
            SET IsLocked = 0, FailedLoginAttempts = 0, UnlockTime = NULL
            WHERE LoginID = @UserID;
        END
    END

    IF @StoredPasswordHash = @PasswordHash 
    BEGIN
        -- sucess
        INSERT INTO AuditLog (UserID, Action, Status, Description)
        VALUES (@UserID, 'Login', 'Success', 'Successful login.');

        PRINT 'Login successful.';

       
        UPDATE UserLogins
        SET FailedLoginAttempts = 0, UpdatedAt = GETDATE()
        WHERE LoginID = @UserID;

        IF EXISTS (SELECT 1 FROM ##CurrentSessionUser WHERE UserID = @UserID)
        BEGIN
            UPDATE ##CurrentSessionUser
            SET LoginName = @LoginName,
                Role = @CurrentRole
            WHERE UserID = @UserID;
        END
        ELSE
        BEGIN
            INSERT INTO ##CurrentSessionUser (UserID, LoginName, Role)
            VALUES (@UserID, @LoginName, @CurrentRole);
        END

        IF @IsFirstLogin = 1
        BEGIN
            UPDATE UserLogins
            SET
                IsFirstLogin = 0,
                UpdatedAt = GETDATE()
            WHERE LoginID = @UserID;

            PRINT 'Login successful. First Time Login. Login Name: ' + @LoginName+ ', Password: ' + @Password;
        END
    END
    ELSE
    BEGIN
     
        UPDATE UserLogins
        SET FailedLoginAttempts = FailedLoginAttempts + 1,
            UpdatedAt = GETDATE()
        WHERE LoginID = @UserID;

        INSERT INTO AuditLog (UserID, Action, Status, Description)
        VALUES (@UserID, 'Login', 'Failed', 'Incorrect password.');

        IF @FailedAttempts + 1  >=  3
        BEGIN
            UPDATE UserLogins
            SET IsLocked = 1, UnlockTime = DATEADD(HOUR, 4, GETDATE()), UpdatedAt = GETDATE()
            WHERE LoginID = @UserID;

            PRINT 'Account locked due to multiple failed attempts. Please try again after 4 hours';
        END
        ELSE
        BEGIN
            PRINT 'Incorrect password';
        END
    END
END;

