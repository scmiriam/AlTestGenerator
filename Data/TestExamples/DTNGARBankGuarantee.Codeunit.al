codeunit 70802 "DTNGAR Bank Guarantee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        BankAccount: Record "Bank Account";
        CustLedgerEntry: record "Cust. Ledger Entry";
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        DTNGARGuaranteeEntry: Record "DTNGAR Guarantee Entry";
        DTNGARSetup: Record "DTNGAR Setup";
        PurchaseOrderHeader: Record "Purchase Header";
        GuaranteeLibrary: Codeunit "DTNGAR Guarantees Library";
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";

        DefualtExchangeRateAmount: Decimal;
        LastGLEntry: Integer;
        LastledgerGuarantees: Integer;
        NumberOfCurrencies: Integer;
        LibraryInventory: Codeunit "Library - Inventory";
        UnitOfMeasure: Record "Unit of Measure";




    //Deposito-Devolución-Ejecutar o Incautar
    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarClienteBankGuarantee()
    var
        Customer: Record Customer;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //**Devolución Return
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;


    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarVendorBankGuarantee()
    var
        Vendor: Record Vendor;

    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        BankAccount.DeleteAll();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarVendorBankGuaranteeExecution()
    var
        Vendor: Record Vendor;

        DTNGARAccountGroup: Record "DTNGAR Account Group";
    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        BankAccount.DeleteAll();
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryERM.CreateBankAccount(BankAccount);
        GuaranteeLibrary.AccountigGroupGuarantee(DTNGARAccountGroup);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarOtherBankGuarantee()
    var
        ContactCompany: Record "Contact";
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, ContactCompany."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
    end;


    //Asociar factura
    [Test]
    [HandlerFunctions('ModalPageHandlerDTNGARInvSelectionToBG1,PageHandlerGuarantees479')]
    procedure ConnectInvoicesBankGuaranteeInvoiceJoin()
    var
        CustomerInvoice: Record Customer;
        i: Integer;
        TotalAmountInicial: Integer;
        InvSelectionToBG1: TestPage "DTNGAR Inv. Selection to BG";
        Navigate: TestPage Navigate;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(CustomerInvoice);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, CustomerInvoice."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        i := 1;
        for i := 1 to 5 do begin
            LibrarySales.MockCustLedgerEntry(CustLedgerEntry, CustomerInvoice."No.");
            CustLedgerEntry.Validate("Remaining Amount (LCY) stats.", Random(1000));
            CustLedgerEntry.Validate(Open, true);
            CustLedgerEntry.Validate("Customer No.", DTNGARGuarantee."Guaranteed No.");
            CustLedgerEntry.Validate("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.Modify(true);
            TotalAmountInicial += CustLedgerEntry."Remaining Amount (LCY) stats.";
        end;

        GuaranteeLibrary.ConnectInvoice(DTNGARGuarantee, TotalAmountInicial);

        InvSelectionToBG1.OpenEdit();
        InvSelectionToBG1.Dimensions.Invoke();
        Navigate.Trap();
        InvSelectionToBG1."&Navigate".Invoke();
        Navigate.Last();

        Navigate.OK().Invoke();
        InvSelectionToBG1.Close();

    end;


    //Deposito-Devolución-Ejecutar 
    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutClienteBankGuarantee()
    var
        Customer: Record Customer;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.Validate(DTNGARGuarantee."Guarantee Type", DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.Modify(true);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //Deposito-Devolución-Ejecutar o Incautar
    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarClienteBankGuaranteeTerm()
    var
        Customer: Record Customer;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Validate(DTNGARGuarantee."Guarantee Type", DTNGARGuarantee."Guarantee Type"::Deposited);

        DTNGARGuarantee.Modify(true);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //**Devolución Return
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;


    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarVendorBankGuaranteeTerm()
    var
        Vendor: Record Vendor;

    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        BankAccount.DeleteAll();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarVendorBankGuaranteeExecutionTerm()
    var
        Vendor: Record Vendor;

        DTNGARAccountGroup: Record "DTNGAR Account Group";
    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        BankAccount.DeleteAll();
        LibraryERM.CreateBankAccount(BankAccount);
        GuaranteeLibrary.AccountigGroupGuarantee(DTNGARAccountGroup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutIncautarOtherBankGuaranteeTerm()
    var
        ContactCompany: Record "Contact";
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, ContactCompany."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();

        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
    end;


    //Asociar factura
    [Test]
    [HandlerFunctions('ModalPageHandlerDTNGARInvSelectionToBG1,PageHandlerGuarantees479')]
    procedure ConnectInvoicesBankGuaranteeInvoiceJoinTerm()
    var
        CustomerInvoice: Record Customer;
        i: Integer;
        TotalAmountInicial: Integer;
        InvSelectionToBG1: TestPage "DTNGAR Inv. Selection to BG";
        Navigate: TestPage Navigate;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(CustomerInvoice);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, CustomerInvoice."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();

        i := 1;
        for i := 1 to 5 do begin
            LibrarySales.MockCustLedgerEntry(CustLedgerEntry, CustomerInvoice."No.");
            CustLedgerEntry.Validate("Remaining Amount (LCY) stats.", Random(1000));
            CustLedgerEntry.Validate(Open, true);
            CustLedgerEntry.Validate("Customer No.", DTNGARGuarantee."Guaranteed No.");
            CustLedgerEntry.Validate("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.Modify(true);
            TotalAmountInicial += CustLedgerEntry."Remaining Amount (LCY) stats.";
        end;

        GuaranteeLibrary.ConnectInvoice(DTNGARGuarantee, TotalAmountInicial);

        InvSelectionToBG1.OpenEdit();
        InvSelectionToBG1.Dimensions.Invoke();
        Navigate.Trap();
        InvSelectionToBG1."&Navigate".Invoke();
        Navigate.Last();
        Navigate.OK().Invoke();
        InvSelectionToBG1.Close();

    end;

    //Asociar factura PageHandlerGuarantees479
    [Test]
    [HandlerFunctions('ModalPageHandlerDTNGARInvSelectionToBG1,RequestPageHandler')]
    procedure ConnectInvoicesBankGuaranteeInvoiceJoinTermNavegate()
    var
        CustomerInvoice: Record Customer;
        i: Integer;
        TotalAmountInicial: Integer;
        GLpage: TestPage "DTNGAR Guarantee Entries";
        InvSelectionToBG1: TestPage "DTNGAR Inv. Selection to BG";
        Navigate: TestPage Navigate;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(CustomerInvoice);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, CustomerInvoice."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        Commit();
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        i := 1;
        for i := 1 to 5 do begin
            LibrarySales.MockCustLedgerEntry(CustLedgerEntry, CustomerInvoice."No.");
            CustLedgerEntry.Validate("Remaining Amount (LCY) stats.", Random(1000));
            CustLedgerEntry.Validate(Open, true);
            CustLedgerEntry.Validate("Customer No.", DTNGARGuarantee."Guaranteed No.");
            CustLedgerEntry.Validate("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.Validate("Document No.", DTNGARGuarantee."No.");
            CustLedgerEntry.Validate("posting date", Today());

            CustLedgerEntry.Validate("DTNGAR Bank Guarantee No.", DTNGARGuarantee."No.");//New
            CustLedgerEntry.Modify(true);
            TotalAmountInicial += CustLedgerEntry."Remaining Amount (LCY) stats.";
        end;
        Commit();
        GuaranteeLibrary.ConnectInvoice(DTNGARGuarantee, TotalAmountInicial);
        DTNGARGuarantee.CalcFields("Deposited Amount");  //New 

        InvSelectionToBG1.OpenEdit();
        InvSelectionToBG1.GoToRecord(CustLedgerEntry);  //NEW
        Navigate.Trap();
        InvSelectionToBG1."&Navigate".Invoke();
        IF Navigate.First() then
            repeat
                IF Navigate."Table Name".Value = 'Guarantee Entry' then begin
                    GLpage.Trap();
                    Navigate."No. of Records".Drilldown();
                    GLpage.OK().Invoke();
                end;
            until Navigate.Next() = false;
        Navigate.OK().Invoke();
        InvSelectionToBG1.Close();
    end;


    //Asociar factura 2
    [Test]
    [HandlerFunctions('ModalPageHandlerDTNGARInvSelectionToBG1,RequestPageHandler,PageHandlerGuarantees479,ModalPageHandler')]
    procedure ConnectInvoicesBankGuaranteeInvoiceJoinTermNavegate2()
    var
        CustomerInvoice: Record Customer;
        i: Integer;
        TotalAmountInicial: Integer;
        GLpage: TestPage "DTNGAR Guarantee Entries";
        InvSelectionToBG1: TestPage "DTNGAR Inv. Selection to BG";
        Navigate: TestPage Navigate;

    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(CustomerInvoice);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, CustomerInvoice."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        Commit();
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);


        i := 1;
        for i := 1 to 5 do begin
            LibrarySales.MockCustLedgerEntry(CustLedgerEntry, CustomerInvoice."No.");
            CustLedgerEntry.Validate("Remaining Amount (LCY) stats.", Random(1000));
            CustLedgerEntry.Validate(Open, true);
            CustLedgerEntry.Validate("Customer No.", DTNGARGuarantee."Guaranteed No.");
            CustLedgerEntry.Validate("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.Validate("Document No.", DTNGARGuarantee."No.");
            CustLedgerEntry.Validate("posting date", Today());

            CustLedgerEntry.Validate("DTNGAR Bank Guarantee No.", DTNGARGuarantee."No.");//New
            CustLedgerEntry.Modify(true);
            TotalAmountInicial += CustLedgerEntry."Remaining Amount (LCY) stats.";
        end;
        Commit();
        GuaranteeLibrary.ConnectInvoice(DTNGARGuarantee, TotalAmountInicial);

        DTNGARGuarantee.CalcFields("Deposited Amount");  //New 

        InvSelectionToBG1.OpenEdit();
        InvSelectionToBG1.GoToRecord(CustLedgerEntry);  //NEW
        //InvSelectionToBG1.Dimensions.Invoke();
        Navigate.Trap();
        InvSelectionToBG1."&Navigate".Invoke();

        IF Navigate.First() then
            repeat
                IF Navigate."Table Name".Value = 'Guarantee Entry' then begin
                    GLpage.Trap();
                    Navigate."No. of Records".Drilldown();
                    GLpage.Dimensions.Invoke();
                    GLpage.Card.Invoke();
                    GLpage.OK().Invoke();
                end;
            until Navigate.Next() = false;
        Navigate.OK().Invoke();
        InvSelectionToBG1.Close();
    end;



    //Deposito-Devolución-Ejecutar 
    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutClienteBankGuaranteeTermReceived()
    var
        Customer: Record Customer;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.Validate(DTNGARGuarantee."Guarantee Type", DTNGARGuarantee."Guarantee Type"::Received);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //Deposito-Devolución-Ejecutar 
    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure PostDeposiEjecutClienteBankGuaranteeTermDeposited()
    var
        Customer: Record Customer;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    [Test]
    procedure TestTableGuaranteeClienteBankGuarantee()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        ModifyFieldManuallyErr: label 'The field %1 cannot be modified manually.', Comment = '"No se puede modificar el campo %1 manualmente."';
        ActualValue: Text;
        ExpectedValue: Text;
        IfErrorTxt: Text;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        asserterror DTNGARGuarantee.Validate("Orden No.", PurchaseOrderHeader."No.");
        ExpectedValue := StrSubstNo(ModifyFieldManuallyErr, DTNGARGuarantee.FieldCaption("Orden No."));
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;





    [Test]
    //AML NEW [HandlerFunctions('MessageHandler')]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler2')]

    procedure TestTableGuaranteeExisteClienteBankGuaranteeCurrency()
    var
        Currency: Record Currency;
        CurrencyExchangeRateTemp: Record "Currency Exchange Rate";
        Customer: Record Customer;
        Assert: Codeunit Assert;
        DeleteBondWithEntriesErr: Label 'A bond with entries cannot be deleted.', Comment = '"No se puede eliminar una fianza con movimientos."';
        ActualValue: Text;
        IfErrorTxt: Text;

    begin
        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        GuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        /*AML NEW Initialize();

        CreateCurrencies(Currency, CurrencyExchangeRateTemp, WorkDate(), NumberOfCurrencies);
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        Currency.FindFirst();
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        */
        Commit();


        //AML NEW DEPOSITAR
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);


        //DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);
        Commit();
        //FIN AML 
        asserterror DTNGARGuarantee.Delete(true);
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(DeleteBondWithEntriesErr, ActualValue, IfErrorTxt);
    end;




    //Deposito-Devolución-Ejecutar 
    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler')]
    procedure TestTableGuaranteeExisteClienteBankGuaranteeChangeCurrency()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        CurrencyExchangeRateTemp: Record "Currency Exchange Rate";
    begin
        CreateCurrencies(Currency, CurrencyExchangeRateTemp, WorkDate(), NumberOfCurrencies);
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        Currency.FindFirst();
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();


        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);


        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Return
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //Ejecutar o Incautar
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Execution);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        asserterror DTNGARGuarantee.Validate("Currency Code", '');
        //NEW 
        //DTNGARGuarantee.Modify();
        //ActualValue := GetLastErrorText();
        //IfErrorTxt := 'El texto del error no es el esperado';
        //Assert.AreEqual('', ActualValue, IfErrorTxt);

    end;



    //MANEJAR VENTANAS
    local procedure CreateCurrencies(var Currency: Record Currency; var TempExpectedCurrencyExchangeRate: Record "Currency Exchange Rate" temporary; StartDate: Date; NumberToInsert: Integer)
    var
        I: Integer;
    begin
        for I := 1 to NumberToInsert do begin
            Clear(Currency);
            LibraryERM.CreateCurrency(Currency);
            // This exchange rate will be used to generate Data Exchange data and to assert values
            TempExpectedCurrencyExchangeRate.Init();
            TempExpectedCurrencyExchangeRate.Validate("Currency Code", Currency.Code);
            TempExpectedCurrencyExchangeRate.Validate("Starting Date", StartDate);
            TempExpectedCurrencyExchangeRate.Insert(true);

            TempExpectedCurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInRange(1, 1000, 2));
            TempExpectedCurrencyExchangeRate.Validate("Exchange Rate Amount", DefualtExchangeRateAmount);
            TempExpectedCurrencyExchangeRate.Validate(
              "Adjustment Exch. Rate Amount", TempExpectedCurrencyExchangeRate."Exchange Rate Amount");
            TempExpectedCurrencyExchangeRate.Validate(
              "Relational Adjmt Exch Rate Amt", TempExpectedCurrencyExchangeRate."Relational Exch. Rate Amount");
            TempExpectedCurrencyExchangeRate.Modify(true);
        end;
    end;

    local procedure Initialize()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
    begin
        Currency.DeleteAll();
        CurrencyExchangeRate.DeleteAll();
        DataExch.DeleteAll(true);
        DataExchDef.DeleteAll(true);
        CurrExchRateUpdateSetup.DeleteAll(true);
        DefualtExchangeRateAmount := 1;
        NumberOfCurrencies := 2;

    end;



    [ModalPageHandler]
    procedure ModalPageHandler(VAR BankGuaranteeCard: TestPage "DTNGAR Bank Guarantee Card")
    begin
        BankGuaranteeCard.OK().INVOKE();
    end;


    [ModalPageHandler]
    procedure ModalPageHandler2(VAR GuaranteeCard: TestPage "DTNGAR Bond Card")
    begin
        GuaranteeCard.OK().INVOKE();
    end;

    [RequestPageHandler]
    procedure RequestPageHandler(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        GuaranteeAccountGroup: Record "DTNGAR Account Group";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
        ActionType: Enum "DTNGAR PostTypeProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";

    begin
        BankAccount.FindFirst();
        GuaranteeAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");

                    RequestPage.IsTransactionPurposal.SetValue(true);//AML Cambio a TRUE
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Execute):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.IsTransactionPurposal.SetValue(false);//AML 
                    RequestPage.ExecutionType.SetValue(EntryType::Account);
                    RequestPage.ExecutionAccount.SetValue(GuaranteeAccountGroup."Short-Term Account (Received)");
                    RequestPage.OK().INVOKE();
                end;

        end;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin
        Msg := 'OK';
    end;


    //MANEJAR VENTANAS ASOCIAR FACTUAS
    [PageHandler]
    procedure ModalPageHandlerDTNGARInvSelectionToBG1(VAR InvSelectionToBG1: TestPage "DTNGAR Inv. Selection to BG")
    begin

        if InvSelectionToBG1.First() then
            repeat
                InvSelectionToBG1."Mark/Unmark Bank Guarantee".Invoke();
            until InvSelectionToBG1.next() = false;

        // InvSelectionToBG1.Description.SetValue(InvSelectionToBG1."DTNGAR Bank Guarantee No.");
        InvSelectionToBG1.OK().Invoke();

    end;

    [ModalPageHandler]
    procedure PageHandlerGuarantees479(var EditDimension: TestPage "Dimension Set Entries");
    begin
        EditDimension.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PageHandlerGuaranteesNavegate(var Navigate: TestPage Navigate);
    begin
        IF Navigate.First() then
            repeat
                Navigate.Show.Invoke();
                Navigate.OK().Invoke();
            until Navigate.Next() = false;


    end;


    [RequestPageHandler]
    procedure RequestPageHandlerBank(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        GuaranteeAccountGroup: Record "DTNGAR Account Group";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
        ActionType: Enum "DTNGAR PostTypeProcess";
    begin
        BankAccount.FindFirst();
        GuaranteeAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    //RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.Account.Lookup();
                    RequestPage.IsTransactionPurposal.SetValue(true);//AML Cambio a TRUE
                    RequestPage.OK().INVOKE();
                end;

        end;
    end;

    [RequestPageHandler]
    procedure RequestPageHandlerAccount(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        GuaranteeAccountGroup: Record "DTNGAR Account Group";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
        ActionType: Enum "DTNGAR PostTypeProcess";
    begin
        BankAccount.FindFirst();
        GuaranteeAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    RequestPage.ExecutionType.SetValue(true);
                    RequestPage.Account.Lookup();
                    RequestPage.IsTransactionPurposal.SetValue(true);//AML Cambio a TRUE
                    RequestPage.OK().INVOKE();
                end;
        end;
    end;


    [ModalPageHandler]
    procedure PageHandlerBank(var BankPage: TestPage "Bank Account List");
    begin
        BankPage.First();
        BankPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PageHandlerAccount(var GLAccountPage: TestPage "G/L Account List");
    begin
        GLAccountPage.First();
        GLAccountPage.OK().Invoke();

    end;
    //Deposito-Devolución-Ejecutar o Incautar
    [Test]
    [HandlerFunctions('RequestPageHandlerBank,PageHandlerBank')]
    procedure PostDeposiEjecutIncautarClienteBankGuaranteeBank()
    var
        Customer: Record Customer;
    begin

        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerAccount,PageHandlerAccount')]
    procedure PostDeposiEjecutIncautarClienteBankGuaranteeAccount()
    var
        Customer: Record Customer;
    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        //check errors
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;


    [Test]
    //[HandlerFunctions('RequestPageHandler')]
    procedure PostingGuaranteSeizureExecution()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        DepositChargeBeforeErr: label 'Firstly you must post the deposit of the guarantee.', Comment = '"Debe registrar primero el depósito de la garantía."';
        ActualValue: Text;
        IfErrorTxt: Text;

    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        // [Then-Comprobacion] Verify: Tiene que mostrar el error
        asserterror GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);

        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(DepositChargeBeforeErr, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure TestGuaranteCheck()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        ErrorDefinitiveErr: Label 'Pre-Guarantee cannot be modified because the guarantee has made a definitive', Comment = '"La pre-garantía no puede modificarse porque se ha convertido a definitiva."';
        ActualValue: Text;
        IfErrorTxt: Text;
    begin
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        DTNGARGuarantee.Validate("Pre Guarantee", true);
        DTNGARGuarantee."Definitive Guarantee Code" := DTNGARGuarantee."No.";
        asserterror DTNGARGuarantee.Modify(true);

        // [Then-Comprobacion] Verify: Tiene que mostrar el error
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';

        //Ejecutar o Incautar
        Assert.AreEqual(ErrorDefinitiveErr, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure TestGuaranteCheck2()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        PreGuaranteeFirstErr: label 'Required Pre-Guarantees enabled. The bond/bank guarantee cannot be created directly.', Comment = '"Pre-garantías obligatorias está activado. No se puede crear el/la aval/fianza directamente."';
        ActualValue: Text;
        IfErrorTxt: Text;

    begin

        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        DTNGARSetup."Pre Guarantee Required" := true;
        DTNGARSetup.Modify();
        Commit();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        asserterror GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        // [Then-Comprobacion] Verify: Tiene que mostrar el error
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';

        //Ejecutar o Incautar
        Assert.AreEqual(PreGuaranteeFirstErr, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure TestGuaranteCheck3()
    begin
        DTNGARSetup.DeleteAll(true);
        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        Commit();
        DTNGARGuarantee.Insert(true);
        Commit();
        // [Then-Comprobacion] Verify: Tiene que mostrar el error



        //Ejecutar o Incautar

    end;

    [RequestPageHandler]
    procedure RPHPostGuaranteeBank(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        DTNGARAccountGroup: Record "DTNGAR Account Group";
        ActionType: Enum "DTNGAR PostTypeProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
    begin
        DTNGARAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;

    [MessageHandler]
    Procedure MessageHandler2(Msg: Text[1024])
    begin
    end;
}