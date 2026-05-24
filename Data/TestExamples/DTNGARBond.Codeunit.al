codeunit 70801 "DTNGAR Bond"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        DTNGARGuaranteeEntry: Record "DTNGAR Guarantee Entry";
        DTNGARSetup: Record "DTNGAR Setup";
        PurchaseOrderHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        DTNGARGuaranteeLibrary: Codeunit "DTNGAR Guarantees Library";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LastBankEntry: Integer;
        LastCustLedgerEntry: Integer;
        LastDetCustLedEntry: Integer;
        LastGLEntry: Integer;
        LastledgerGuarantees: Integer;
        DTNGARBond: TestPage "DTNGAR Bond Card";
        DefualtExchangeRateAmount: Decimal;
        NumberOfCurrencies: Integer;
        LibraryInventory: Codeunit "Library - Inventory";
        UnitOfMeasure: Record "Unit of Measure";


    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure TestTableGuaranteeExisteClienteBankGuaranteeChangeCurrency()
    var
        Currencyrec: Record Currency;
        CurrencyExchangeRateTemp: Record "Currency Exchange Rate";
        ChangeCurrencyWithbondEntriesErr: label 'A bond with entries cannot be modified it.', Comment = '"No se puede cambiar divisa en una fianza con movimientos."';

        ActualValue: Text;
        IfErrorTxt: Text;
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //AML NEW 
        CreateCurrencies(Currencyrec, CurrencyExchangeRateTemp, WorkDate(), NumberOfCurrencies);
        Currencyrec.FindFirst();
        /*Initialize();
        
        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibrarySales.CreateCustomer(Customer);
        Currencyrec.FindFirst();
        //AML NEW Customer.Validate("Currency Code", Currencyrec.Code);
        //AML NEW Customer.Modify(true);

        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
*/
        Commit();


        //AML NEW DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);


        //DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);
        Commit();
        //asserterror DTNGARGuarantee.Validate("Currency Code", Currencyrec.Code);
        //DTNGARGuarantee.Modify();
        //ActualValue := GetLastErrorText();
        //IfErrorTxt := 'El texto del error no es el esperado';
        //Assert.AreEqual(ChangeCurrencyWithbondEntriesErr, ActualValue, IfErrorTxt);

    end;

    [Test]
    procedure TestTableGuaranteeExisteClienteBankGuaranteeChangeFactorCurrency()
    var
        CurrencyFactorErr: label 'cannot be specified without %1.', Comment = '"no se puede especificar sin %1."';
        ExpectedValue: Text;
        ActualValue: Text;
        IfErrorTxt: Text;
    begin


        Initialize();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        asserterror DTNGARGuarantee.Validate("Currency Factor", 1);
        // 'Currency Factor cannot be specified without Currency Code. en Guarantee Type="bond",No.="GL00000001".' 
        ExpectedValue := Format('Currency Factor ' + StrSubstNo(CurrencyFactorErr, DTNGARGuarantee.FieldName("Currency Code")));
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(copystr(ExpectedValue, 1, 40), Copystr(ActualValue, 1, 40), IfErrorTxt);

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

    //***(PROCESO REGISTRO  -> BANCO)***(TIPO AVALDO -> CLIENTE)***(TIPO FIANZA -> RECIBIDO)
    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure PostGuaranteeCustomerReceivedBank()
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //EJECUTAR/INCAUTAR
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //RECLASIFICAR
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //***(PROCESO REGISTRO  -> BANCO)***(TIPO AVALDO -> PROVEEDOR)***(TIPO FIANZA -> RECIBIDO)
    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure PostGuaranteeVendorReceivedBank()
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //RECLASIFICAR
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> BANCO)***(TIPO AVALDO -> OTRO)***(TIPO FIANZA -> RECIBIDO)
    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure PostGuaranteeOtherReceivedBank()
    var
        ContactCompany: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, ContactCompany."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //RECLASIFICAR
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //***(PROCESO REGISTRO  -> BANCO)***(TIPO AVALDO -> CLIENTE)***(TIPO FIANZA -> DEPOSITADO)
    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure PostGuaranteeCustomerDepositBank()
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);

        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //RECLASIFICAR
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //***(PROCESO REGISTRO  -> BANCO)***(TIPO AVALDO -> PROVEEDOR)***(TIPO FIANZA -> DEPOSITADO)
    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure PostGuaranteeVendorDepositBank()
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //RECLASIFICAR
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> BANCO)***(TIPO AVALDO -> OTROS)***(TIPO FIANZA -> DEPOSITADO)**
    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler')]
    procedure PostGuaranteeDepositOthersBank()
    var
        Contact: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Contact."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEPOSITAR
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //RECLASIFICAR
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> CLIENTE)***(TIPO FIANZA -> RECIBIDO)**
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeCustomerReceivedAccount()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> PROVEEDOR)***(TIPO FIANZA -> RECIBIDO)**
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeVendorReceivedAccount()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> OTROS)***(TIPO FIANZA -> RECIBIDO)**
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeOthersReceivedAccount()
    var
        ContactCompany: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, ContactCompany."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //***(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> CLIENTE)***(TIPO FIANZA -> DEPOSITO)
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeCustomerDepositAccount()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;



    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> PROVEEDOR)***(TIPO FIANZA -> DEPOSITO)
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeVendorDepositAccount()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //***(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> OTROS)***(TIPO FIANZA -> DEPOSITO)
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeOthersDepositAccount()
    var
        Contact: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Contact."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //************REG. DIARIO-> TIPO INCAUTACION = Received  ,REG. TIPO -> CUENTA ********************* 
    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    procedure PostJournalRecibGuaranteeCustomerJournal()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
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

    [ModalPageHandler]
    procedure ModalPageHandler2(VAR GuaranteeCard: TestPage "DTNGAR Bond Card")
    begin
        GuaranteeCard.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageModifyEntry(VAR DTNGARModifyEntryDetail: TestPage "DTNGARModify Entry Detail")
    begin
        DTNGARModifyEntryDetail.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler,ModalPageHandler2,ModalPageModifyEntry')]
    procedure PostJournalRecibGuaranteeVendorJournalNavegate3()
    var
        GLGurantee: Record "DTNGAR Guarantee Entry";
        GLPageGurantee: TestPage "DTNGAR Guarantee Entries";
        Navigate: TestPage Navigate;

    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARGuarantee.CalcFields("Deposited Amount");


        GLGurantee.Reset();
        GLGurantee.SetRange("Guarantees No.", DTNGARGuarantee."No.");
        GLGurantee.SetRange("Entry Type", GLGurantee."Entry Type"::Deposit);
        GLGurantee.FindFirst();

        GLPageGurantee.OpenEdit();
        GLPageGurantee.GoToRecord(GLGurantee);
        Navigate.Trap();
        GLPageGurantee."&Navigate".Invoke();
        Navigate.First();
        Navigate.OK().Invoke();


        GLPageGurantee.Card.Invoke();
        GLPageGurantee."Modify Entry Detail".Invoke();
        GLPageGurantee.OK().Invoke();

    end;


    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    procedure PostJournalRecibGuaranteeVendorJournal()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    procedure PostJournalRecibGuaranteeOthersJournal()
    var
        ContactCompany: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, ContactCompany."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;


    //************REG. DIARIO-> TIPO INCAUTACION=DEPOSITADA ,REG. TIPO -> CUENTA *********************
    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    procedure PostJournalDepositGuaranteeCustomerJournal()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    procedure PostJournalDepositGuaranteeVendorJournal()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    [Test]
    [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    procedure PostJournalDepositGuaranteeOthersJournal()
    var
        Contact: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Contact."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);


        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastLedgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;


    //************REG. DIARIO-> TIPO INCAUTACION= Received ,REG. TIPO -> BANCO *********************
    [Test]
    [HandlerFunctions('RPHRecibPostGuarantee,MessageHandler,ModalPageHandler39,ConfirmHandler')]
    procedure PostRecibGuaranteeCustomerJournal()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckBankLedgerEntry(LastBankEntry);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckBankLedgerEntry(LastBankEntry);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckCustomerLedgerEntry(LastCustLedgerEntry, DTNGARbond);
        DTNGARGuaranteeLibrary.CheckCustDetailLedgEntry(LastDetCustLedEntry, DTNGARbond);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARbond.Close();

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

    end;
    //************REG. DIARIO-> TIPO INCAUTACION= Deposited ,REG. TIPO -> BANCO *********************
    [Test]
    [HandlerFunctions('RPHDepositPostGuarantee,MessageHandler,ModalPageHandler39,ConfirmHandler')]
    procedure PostDepositGuaranteeCustomerJournal()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEPOSITO
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterDeposit(DTNGARbond);
        DTNGARbond.Close();

        //Verificación tras registro
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckBankLedgerEntry(LastBankEntry);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        //Verificación tras registro
        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountsAfterReturn(DTNGARbond);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckBankLedgerEntry(LastBankEntry);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        //Verificación tras registro
        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckAmountAfterRun(DTNGARbond);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckCustomerLedgerEntry(LastCustLedgerEntry, DTNGARbond);
        DTNGARGuaranteeLibrary.CheckCustDetailLedgEntry(LastDetCustLedEntry, DTNGARbond);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARbond.Close();

        DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //RECLASIFICACION
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        DTNGARGuaranteeLibrary.RunReclasGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();

        //Verificación tras registro
        DTNGARbond.OpenEdit();
        DTNGARbond.GoToRecord(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckFieldsAfterReclas(DTNGARbond);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARbond.Close();
    end;

    /******************Term************///////////////////


    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> CLIENTE)***(TIPO FIANZA -> RECIBIDO)**
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeCustomerReceivedAccountTerm()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> PROVEEDOR)***(TIPO FIANZA -> RECIBIDO)**
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeVendorReceivedAccountTerm()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;


    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> OTROS)***(TIPO FIANZA -> RECIBIDO)**
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeOthersReceivedAccountTerm()
    var
        ContactCompany: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, ContactCompany."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //***(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> CLIENTE)***(TIPO FIANZA -> DEPOSITO)
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeCustomerDepositAccountTerm()
    var
    //Customer: Record Customer;
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;



    //**(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> PROVEEDOR)***(TIPO FIANZA -> DEPOSITO)
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeVendorDepositAccountTerm()
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;

    //***(PROCESO REGISTRO  -> CUENTA)***(TIPO AVALDO -> OTROS)***(TIPO FIANZA -> DEPOSITO)
    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler')]
    procedure PostGuaranteeOthersDepositAccountTerm()
    var
        Contact: Record Contact;
        LibraryMarketing: codeunit "Library - Marketing";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupbond(DTNGARSetup);
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Contact."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Other, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        DTNGARGuarantee.validate(DTNGARGuarantee.Term, DTNGARGuarantee.Term::Long);
        DTNGARGuarantee.Modify(true);
        Commit();
        //Deposit
        DTNGARGuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Return
        DTNGARGuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Seize
        DTNGARGuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        DTNGARGuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Reclasify
        DTNGARGuaranteeLibrary.ReclassifyGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        DTNGARGuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);
    end;



    /***************************************** MANEJADOR DE VENTANAS **********************************/
    [ModalPageHandler]
    procedure ModalPageHandler(VAR DTNGARBankGuaranteeCard: TestPage "DTNGAR Bank Guarantee Card")
    begin
        DTNGARBankGuaranteeCard.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModPagHanGeneraljournal(VAR GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageHandler250(VAR GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageHandler39(VAR GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().INVOKE();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    Procedure MessageHandlerNIF(Msg: Text[1024])
    var
        FirstPart: Text[1024];
        posicion: Integer;
        NifDuplicadoErr: Label 'Error: It has not shown any message, when entering two guarantees of the same type of deposit.',
                        comment = '"Error: No ha mostrado ningun mensaje, al introducir dos Garantias de tipo fianza con mismo NIF"';
        HasExistLbl: Label 'Ya existe el avalado', comment = '"Ya existe el avalado"';

    begin
        FirstPart := HasExistLbl;
        posicion := StrPos(Msg, FirstPart);
        Assert.IsTrue(posicion <> 0, NifDuplicadoErr);
    end;

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    procedure RPHPostGuarantee(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
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
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    //Si es Plazo = Largo o corto(Short)
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        // Si es recibida o depositada
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.SeizureType.SetValue(SeizeType::Account);
                    //Si es Plazo = Largo o corto(Short)
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        // Si es recibida o depositada
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.SeizureAccount.SetValue(DTNGARAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.SeizureAccount.SetValue(DTNGARAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.SeizureAccount.SetValue(DTNGARAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.SeizureAccount.SetValue(DTNGARAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    //Si es Plazo = Largo o corto(Short)
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        // Si es recibida o depositada
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(DTNGARAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
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


    //************REG. DIARIO-> TIPO INCAUTACION= Deposited Y Received ,REG. TIPO -> EntryType::Account *********************
    [ModalPageHandler]
    procedure JournalModalPageHandler(VAR DTNGARBankGuaranteeCard: TestPage "DTNGAR Bank Guarantee Card")
    begin
        DTNGARBankGuaranteeCard.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure JournalModalPageHandler39(VAR GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure JournalModalPageHandler250(VAR GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.OK().INVOKE();
    end;

    [RequestPageHandler]
    procedure JournalRPHPostGuarantee(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        GuaranteeAccountGroup: Record "DTNGAR Account Group";
        ActionType: Enum "DTNGAR PostTypeProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
    begin
        GuaranteeAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.SeizureType.SetValue(EntryType::Account);
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.SeizureAccount.SetValue(GuaranteeAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.SeizureAccount.SetValue(GuaranteeAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.SeizureAccount.SetValue(GuaranteeAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.SeizureAccount.SetValue(GuaranteeAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;

    //************REG. DIARIO-> TIPO INCAUTACION= Deposited Y Received ,REG. TIPO -> EntryType::BANCO *********************
    [RequestPageHandler]
    procedure RPHRecibPostGuarantee(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        ActionType: Enum "DTNGAR PostTypeProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
    begin
        BankAccount.FindFirst();
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure RPHDepositPostGuarantee(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        ActionType: Enum "DTNGAR PostTypeProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
    begin
        BankAccount.FindFirst();
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(-10000, -40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(-10, -1000, 2));
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;

            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;


    [ModalPageHandler]
    procedure ModalPageHandlerPurchaList(VAR PurchaseOrderCard: TestPage "Purchase List")
    begin
        PurchaseOrderCard.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageHandlerDimension(VAR dim: TestPage "Dimension Value List")
    begin
        dim.OK().INVOKE();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ModalPageHandlerPurchaList')]
    procedure TestTableGuaranteeBankGuaranteeLookUp()
    Var
        TestPagebond: TestPage "DTNGAR Bond Card";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        PurchaseOrderHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseOrderHeader.Modify();
        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        TestPagebond.OpenEdit();
        TestPagebond.GoToRecord(DTNGARGuarantee);
        TestPagebond."Orden No.".Lookup();
        TestPagebond.Close()
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestTableGuaranteeBankGuaranteeLookUpDeleteOrdenN()
    Var
        TestPagebond: TestPage "DTNGAR Bond Card";
        Field001Err: Label '%1 field it is empty.', comment = '"El campo %1 está vacío."';
        ActualValue: Text;
        IfErrorTxt: Text;
        ExpectedValue: Text;
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        PurchaseOrderHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseOrderHeader.Modify();

        Commit();
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee."Guaranteed No." := '';
        DTNGARGuarantee.Modify();
        Commit();

        TestPagebond.OpenEdit();
        TestPagebond.GoToRecord(DTNGARGuarantee);
        asserterror TestPagebond."Orden No.".Lookup();
        ExpectedValue := StrSubstNo(Field001Err, DTNGARGuarantee.FieldCaption("Guaranteed No."));
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';


        //Ejecutar o Incautar
        Assert.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
        TestPagebond.Close()
    end;

    [Test]

    procedure TestTableGuaranteeValidateReturnReason()
    var
        DTNGARCodesSetup: Record "DTNGAR Codes Setup";
    begin
        DTNGARCodesSetup.DeleteAll();
        DTNGARCodesSetup.Validate(Type, DTNGARCodesSetup.Type::"bond Return Reason");
        DTNGARCodesSetup.Validate(Code, 'code');
        DTNGARCodesSetup.Validate(Description, 'code');
        DTNGARCodesSetup.Insert(true);
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);

        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuarantee.Validate("Return Reason", 'code');
        DTNGARGuarantee.Modify(true);

    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerDimension')]
    procedure TestTableGuaranteeDimension1LookUp()
    Var
        TestPagebond: TestPage "DTNGAR Bond Card";
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        TestPagebond.OpenEdit();
        TestPagebond.GoToRecord(DTNGARGuarantee);
        TestPagebond."Global Dimension 1 Code".Lookup();
        TestPagebond.Close()
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerDimension')]
    procedure TestTableGuaranteeDimension2LookUp()
    Var
        TestPagebond: TestPage "DTNGAR Bond Card";

    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        TestPagebond.OpenEdit();
        TestPagebond.GoToRecord(DTNGARGuarantee);
        TestPagebond."Global Dimension 2 Code".Lookup();
        TestPagebond.Close()
    end;

    [Test]
    procedure TestTableGuarantee3OnValidate()
    Var
        TestPagebond: TestPage "DTNGAR Bond Card";

    begin
        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        TestPagebond.OpenEdit();
        TestPagebond.GoToRecord(DTNGARGuarantee);
        TestPagebond."Guaranteed Type".SetValue(DTNGARGuarantee.Type::bond);
        TestPagebond."Guaranteed Type".SetValue(DTNGARGuarantee.Type::"Bank Guarantee");
        TestPagebond.Close()
    end;

    [Test]
    procedure TestTableGuaranteeBankGuaranteeValidate1()
    Var
        GuaranteedNoErr: Label 'Guaranteed No. must be filled in the guarantee.', Comment = '"Nº avalado debe estar definido en la garantía."';
        ActualValue: Text;
        IfErrorTxt: Text;
    begin

        DTNGARGuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);

        DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, '', PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        DTNGARGuaranteeLibrary.DeleteJournalLine();
        asserterror DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        DTNGARGuaranteeLibrary.PostJournalLine();
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';

        //Ejecutar o Incautar
        Assert.AreEqual(GuaranteedNoErr, ActualValue, IfErrorTxt);

    end;

    //Comentamos este test ya que ahora es una pregunta y no un error

    // [Test]
    // [HandlerFunctions('JournalRPHPostGuarantee,MessageHandler,JournalModalPageHandler39,ConfirmHandler')]
    // procedure TestTableGuaranteeBankGuaranteeValidate2()
    // Var
    //     CurrentAmounErr: Label 'Guaranteed No. cannot be changed because the guarantee has current amount.', Comment = '"El Nº Avalado no puede ser cambiado porque la garantía tiene imporrte vigente."';
    //     ActualValue: Text;
    //     IfErrorTxt: Text;

    // begin

    //     DTNGARGuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
    //     LibraryPurchase.CreateVendor(Vendor);
    //     LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
    //     LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
    //     DTNGARGuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::bond, DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
    //     Commit();

    //     DTNGARGuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

    //     //DEPOSITO
    //     DTNGARGuaranteeLibrary.DeleteJournalLine();
    //     DTNGARGuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
    //     DTNGARGuaranteeLibrary.PostJournalLine();

    //     DTNGARGuarantee.CalcFields("Current Amount");
    //     asserterror DTNGARGuarantee.Validate("Guaranteed No.", '');


    //     ActualValue := GetLastErrorText();
    //     IfErrorTxt := 'El texto del error no es el esperado';
    //     //Ejecutar o Incautar
    //     Assert.AreEqual(CurrentAmounErr, ActualValue, IfErrorTxt);

    // end;

}