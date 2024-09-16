CREATE OR ALTER PROCEDURE TransferMoney
    @FromAccountNumber NVARCHAR(20),
    @ToAccountNumber NVARCHAR(20),
    @Amount DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT, @UserRole NVARCHAR(20);
    DECLARE @FromAccountID INT, @ToAccountID INT;

    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        PRINT 'No current session user found. Please log.';
        RETURN;
    END

    SELECT @UserID = UserID, @UserRole = Role
    FROM ##CurrentSessionUser;

    SELECT @FromAccountID = A.AccountID
    FROM AccountUsers AU
    JOIN Accounts A ON AU.AccountID = A.AccountID
    WHERE AU.UserID = @UserID AND A.AccountNumber = @FromAccountNumber;

    IF @FromAccountID IS NULL
    BEGIN
        PRINT 'You are not authorized to transfer money from this account or the account does not exist.';
        RETURN;
    END

    SELECT @ToAccountID = A.AccountID
    FROM Accounts A
    WHERE A.AccountNumber = @ToAccountNumber;

    IF @ToAccountID IS NULL
    BEGIN
        PRINT 'The destination account does not exist.';
        RETURN;
    END

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        IF (SELECT Balance FROM Accounts WHERE AccountID = @FromAccountID) < @Amount
        BEGIN
            THROW 50000, 'Insufficient funds in the source account.', 1;
        END

        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccountID;

        UPDATE Accounts
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToAccountID;

        INSERT INTO Transactions (AccountID, TransactionTypeID, Amount, TransactionDate, Description)
        VALUES (@FromAccountID, (SELECT TransactionTypeID FROM TransactionTypes WHERE TransactionTypeName = 'Transfer'), @Amount, GETDATE(), 'Transfer from ' + @FromAccountNumber + ' to ' + @ToAccountNumber);

        COMMIT TRANSACTION;

        PRINT 'Money transferred successfully.';
    END TRY
    BEGIN CATCH
       
        ROLLBACK TRANSACTION;

        PRINT 'Transaction failed. Please try again.';
    END CATCH;
END;

------------------------------------------------------------- 



CREATE OR ALTER PROCEDURE CreditMoney
    @ToAccountNumber NVARCHAR(20),
    @Amount DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT, @UserRole NVARCHAR(20);
    DECLARE @ToAccountID INT;

    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        PRINT 'No current session user found. Please log in first.';
        RETURN;
    END

    SELECT @UserID = UserID, @UserRole = Role
    FROM ##CurrentSessionUser;

    SELECT @ToAccountID = A.AccountID
    FROM AccountUsers AU
    JOIN Accounts A ON AU.AccountID = A.AccountID
    WHERE AU.UserID = @UserID AND A.AccountNumber = @ToAccountNumber;

    IF @ToAccountID IS NULL
    BEGIN
        PRINT 'You are not authorized to credit money to this account or the account does not exist.';
        RETURN;
    END

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
     
        UPDATE Accounts
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToAccountID;

       
        INSERT INTO Transactions (AccountID, TransactionTypeID, Amount, TransactionDate, Description)
        VALUES (@ToAccountID, (SELECT TransactionTypeID FROM TransactionTypes WHERE TransactionTypeName = 'Credit'), @Amount, GETDATE(), 'Credit to account ' + @ToAccountNumber);

        COMMIT TRANSACTION;

        PRINT 'Money credited successfully.';
    END TRY
    BEGIN CATCH
       
        ROLLBACK TRANSACTION;

        PRINT 'Transaction failed. Please try again.';
    END CATCH;
END;


-----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE DebitMoney
    @FromAccountNumber NVARCHAR(20),
    @Amount DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT, @UserRole NVARCHAR(20);
    DECLARE @FromAccountID INT;

    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        PRINT 'No current session user found. Please log in first.';
        RETURN;
    END

    SELECT @UserID = UserID, @UserRole = Role
    FROM ##CurrentSessionUser;


    SELECT @FromAccountID = A.AccountID
    FROM AccountUsers AU
    JOIN Accounts A ON AU.AccountID = A.AccountID
    WHERE AU.UserID = @UserID AND A.AccountNumber = @FromAccountNumber;

    IF @FromAccountID IS NULL
    BEGIN
        PRINT 'You are not authorized to debit money from account or the account does not exist.';
        RETURN;
    END

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        IF (SELECT Balance FROM Accounts WHERE AccountID = @FromAccountID) < @Amount
        BEGIN
            THROW 50000, 'Insufficient funds in the account', 1;
        END

        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccountID;

        INSERT INTO Transactions (AccountID, TransactionTypeID, Amount, TransactionDate, Description)
        VALUES (@FromAccountID, (SELECT TransactionTypeID FROM TransactionTypes WHERE TransactionTypeName = 'Debit'), @Amount, GETDATE(), 'Debit from account ' + @FromAccountNumber);

        COMMIT TRANSACTION;

        PRINT 'Money debited successfully.';
    END TRY
    BEGIN CATCH
        -- Rollback transaction
        ROLLBACK TRANSACTION;

        PRINT 'Transaction failed, Please try again.';
    END CATCH;
END;


----------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE GetTransactions
    @AccountNumber NVARCHAR(20),
    @NumberOfTransactions INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT, @UserAccountID INT;

    IF OBJECT_ID('tempdb..##CurrentSessionUser') IS NULL
    BEGIN
        PRINT 'No current session user found. Please log in first.';
        RETURN;
    END

    SELECT @UserID = UserID
    FROM ##CurrentSessionUser;

    SELECT @UserAccountID = AU.AccountID
    FROM AccountUsers AU
    JOIN Accounts A ON AU.AccountID = A.AccountID
    WHERE AU.UserID = @UserID AND A.AccountNumber = @AccountNumber;

    IF @UserAccountID IS NULL
    BEGIN
        PRINT 'You are not authorized to view transactions from this account.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE AccountNumber = @AccountNumber)
    BEGIN
        SELECT 'Account number does not exist.' AS Message;
        RETURN;
    END

    SELECT TOP (@NumberOfTransactions)
        T.TransactionID,
        T.AccountID,
        TT.TransactionTypeName AS TransactionType,
        T.Amount,
        T.TransactionDate,
        T.Description
    FROM
        Transactions T
    INNER JOIN
        Accounts A ON T.AccountID = A.AccountID
    INNER JOIN
        TransactionTypes TT ON T.TransactionTypeID = TT.TransactionTypeID
    WHERE
        A.AccountNumber = @AccountNumber
    ORDER BY
        T.TransactionDate DESC;
END;

