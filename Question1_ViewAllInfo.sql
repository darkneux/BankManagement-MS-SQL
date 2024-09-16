CREATE FUNCTION dbo.CalculateUpdatedBalance
(
    @AccountID INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @CurrentBalance DECIMAL(18, 2);
    DECLARE @NewBalance DECIMAL(18, 2);
    DECLARE @InterestRate DECIMAL(5, 2) = 0.02;
    DECLARE @DeductionAmount DECIMAL(18, 2) = 500;

    SELECT @CurrentBalance = Balance
    FROM Accounts
    WHERE AccountID = @AccountID;

    IF @CurrentBalance > 10000
    BEGIN
        SET @NewBalance = @CurrentBalance * (1 + @InterestRate);
    END
    ELSE
    BEGIN
        SET @NewBalance = @CurrentBalance - @DeductionAmount;
    END

    RETURN @NewBalance;
END;



EXEC UpdateAccountBalance;

CREATE OR ALTER PROCEDURE UpdateAccountBalance
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        PRINT 'No current session user found. Please log in first.';
        RETURN;
    END

    DECLARE @Role NVARCHAR(20);
    SELECT @Role = Role
    FROM ##CurrentSessionUser;

    IF @Role != 'Employee' AND @Role != 'Admin'
    BEGIN
        PRINT 'Unauthorized action. Only employees can execute this stored procedure.';
        RETURN;
    END

    DECLARE account_cursor CURSOR FOR
    SELECT AccountID
    FROM Accounts;

    DECLARE @AccountID INT;
    DECLARE @UpdatedBalance DECIMAL(18, 2);

    OPEN account_cursor;

    FETCH NEXT FROM account_cursor INTO @AccountID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @UpdatedBalance = dbo.CalculateUpdatedBalance(@AccountID);

        UPDATE Accounts
        SET Balance = @UpdatedBalance,
            UpdatedAt = GETDATE()
        WHERE AccountID = @AccountID;

        FETCH NEXT FROM account_cursor INTO @AccountID;
    END

    CLOSE account_cursor;
    DEALLOCATE account_cursor;
END;


---------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE spGetAllAccountInformation 
    @UserID INT 
AS
BEGIN
    DECLARE @Role NVARCHAR(20);

    
    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        PRINT 'No current session user found. Please log in first.';
        RETURN;
    END

    SELECT @Role = Role
    FROM ##CurrentSessionUser;

   
    IF @Role = 'Admin'
    BEGIN
        SELECT 
            UL.LoginID,
            U.FirstName + ' ' + ISNULL(U.MiddleName, '') + ' ' + U.LastName AS UserName,
            A.AccountNumber,
            A.Balance,
            T.TransactionDate,
            T.Amount,
            TT.TransactionTypeName,
            TS.StatusName AS TransactionStatus
        FROM UserLogins UL
        LEFT JOIN Users U ON UL.LoginID = U.LoginID
        LEFT JOIN AccountUsers AU ON U.UserID = AU.UserID
        LEFT JOIN Accounts A ON AU.AccountID = A.AccountID
        LEFT JOIN Transactions T ON A.AccountID = T.AccountID
        LEFT JOIN TransactionTypes TT ON T.TransactionTypeID = TT.TransactionTypeID
        LEFT JOIN TransactionStatuses TS ON T.TransactionStatusID = TS.TransactionStatusID
        WHERE UL.LoginID = @UserID;
    END
    ELSE
    BEGIN
        PRINT 'Access Denied: You do not have permission to view this information.';
    END
END;

