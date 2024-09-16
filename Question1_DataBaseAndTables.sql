
CREATE DATABASE BankManagementSystem
USE BankManagementSystem
--DROP DATABASE BankManagementSystem


CREATE TABLE UserLogins (
    LoginID INT PRIMARY KEY IDENTITY(1,1),
    LoginName NVARCHAR(50) UNIQUE,
    PasswordHash VARBINARY(256), 
    IsFirstLogin BIT DEFAULT 1, 
    FailedLoginAttempts INT DEFAULT 0, 
    IsLocked BIT DEFAULT 0, 
    LastFailedLogin DATETIME, 
    UnlockTime DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    LoginID INT UNIQUE, 
    FirstName NVARCHAR(20) NOT NULL,
    MiddleName NVARCHAR(20),
    LastName NVARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (LoginID) REFERENCES UserLogins(LoginID)
);

CREATE TABLE Addresses (
    AddressID INT PRIMARY KEY IDENTITY(1,1),
    AddressLine NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    UserID INT, 
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

CREATE TABLE PhoneNumbers (
    PhoneNumberID INT PRIMARY KEY IDENTITY(1,1),
    PhoneNumber NVARCHAR(15) UNIQUE,
    UserID INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

CREATE TABLE Emails (
    EmailID INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(100) UNIQUE,
    UserID INT, 
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100) UNIQUE
);

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT UNIQUE,
    DepartmentID INT,
    Designation NVARCHAR(100),
    Age INT,
    JoinDate DATE,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE AccountTypes (
    AccountTypeID INT PRIMARY KEY IDENTITY(1,1),
    AccountTypeName NVARCHAR(50) UNIQUE
);

INSERT INTO AccountTypes VALUES('Savings');
INSERT INTO AccountTypes VALUES('Current');

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT UNIQUE, 
    AccountTypeID INT, 
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AccountTypeID) REFERENCES AccountTypes(AccountTypeID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Accounts Table
CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY IDENTITY(1,1),
    AccountNumber NVARCHAR(20) UNIQUE NOT NULL,
    Balance DECIMAL(18, 2),
    AccountTypeID INT, 
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AccountTypeID) REFERENCES AccountTypes(AccountTypeID)
);

CREATE TABLE TransactionStatuses (
    TransactionStatusID INT PRIMARY KEY IDENTITY(1,1),
    StatusName NVARCHAR(50) UNIQUE,
);



INSERT INTO TransactionStatuses VALUES('Success');
INSERT INTO TransactionStatuses VALUES('Failed');
INSERT INTO TransactionStatuses VALUES('Insufficient Funds');
INSERT INTO TransactionStatuses VALUES('Pending');

CREATE TABLE TransactionTypes (
    TransactionTypeID INT PRIMARY KEY IDENTITY(1,1),
    TransactionTypeName NVARCHAR(50) UNIQUE
);

INSERT INTO TransactionTypes VALUES('Transfer');
INSERT INTO TransactionTypes VALUES('Debit');
INSERT INTO TransactionTypes VALUES('Credit');

CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    AccountID INT,
    TransactionTypeID INT,
    TransactionStatusID INT,
    Amount DECIMAL(18, 2),
    TransactionDate DATETIME DEFAULT GETDATE(),
    Description NVARCHAR(255),
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID),
    FOREIGN KEY (TransactionTypeID) REFERENCES TransactionTypes(TransactionTypeID),
    FOREIGN KEY (TransactionStatusID) REFERENCES TransactionStatuses(TransactionStatusID)
);

CREATE TABLE AccountUsers (
    AccountID INT,
    UserID INT,
    PRIMARY KEY (AccountID, UserID),
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

CREATE TABLE AuditLog (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    Action NVARCHAR(50),
    Status NVARCHAR(50),
    Timestamp DATETIME DEFAULT GETDATE(),
    Description NVARCHAR(255),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);


DROP TABLE UserLogins
DROP TABLE Users
DROP TABLE Addresses
DROP TABLE Emails
DROP TABLE PhoneNumbers
DROP TABLE Departments
DROP TABLE Employees
DROP TABLE Accounts
DROP TABLE Customers
DROP TABLE Transactions
DROP TABLE TransactionStatuses
DROP TABLE TransactionTypes
DROP TABLE AccountTypes
DROP TABLE AccountUsers
DROP TABLE AuditLog
