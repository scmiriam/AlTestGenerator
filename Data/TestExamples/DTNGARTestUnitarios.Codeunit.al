codeunit 70800 "DTNGAR TestUnitarios"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        BankAccount: Record "Bank Account";
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        DTNGARSetup: Record "DTNGAR Setup";
        PurchaseOrderHeader: Record "Purchase Header";
        DTNGARUserSetup: record "User Setup";
        GuaranteeLibrary: Codeunit "DTNGAR Guarantees Library";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LastGLEntry: Integer;
        LastledgerGuarantees: Integer;
        LibraryInventory: Codeunit "Library - Inventory";
        UnitOfMeasure: Record "Unit of Measure";



    [Test]
    //[HandlerFunctions('RequestPageHandler')]
    procedure FieldEnabledEndorsementBankGuarante()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        //ExistsGuaranteedMsg: label 'Dimensions must be defined in the guarantee', Comment = '"Las dimensiones deben estar definidas en la garantía."';
        ActualValue: Text;
        IfErrorTxt: Text;
        DimensionsMsg: Label 'Dimensions must be filled in the guarantee.', Comment = '"Las dimensiones deben estar definidas en la garantía."';
        BGExistsErr: label 'There is already a bank guarantee with the same No..', Comment = '"Ya existe un aval con el mismo Nº."';
    //BGExistsErr: label 'There is already a bank guarantee with the same No..', Comment = '"Ya existe un aval con el mismo Nº."';

    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);

        //Test  Captura error Deposito Falta dimensiones asignadas 
        LibrarySales.CreateCustomer(Customer);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        GuaranteeLibrary.ModifyGuaranteeDimension(DTNGARGuarantee);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // [Then-Comprobacion] Verify: Tiene que mostrar el error
        asserterror GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);//Deposit dimension
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(DimensionsMsg, ActualValue, IfErrorTxt);
        //Test Captura error ya existe deposito
        LibrarySales.CreateCustomer(Customer);

        asserterror GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(BGExistsErr, ActualValue, IfErrorTxt);
        Commit();


        asserterror GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);//Deposit1
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(DimensionsMsg, ActualValue, IfErrorTxt);

    end;

    [Test]
    procedure FieldEnabledEndorsementBankGuaranBondCountTest()
    var
        Customer: Record Customer;
    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);

        //Test Campos AVALES
        GuaranteeLibrary.CreateGuaranteeBankGuaranteTest(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();

        GuaranteeLibrary.CreateGuaranteeBankGuaranteTest(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        //Test Campos FIANZAS 
        //asserterror 
        GuaranteeLibrary.CreateGuaranteeBankGuaranteTest(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

    end;

    [Test]
    procedure FieldEnabledEndorsementBankGuaranBond()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        BondExistsErrErr: label 'There is already a bond with the same No..', Comment = '"Ya existe una fianza con el mismo Nº."';
        ActualValue: Text;
        IfErrorTxt: Text;
    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);


        //Test Campos AVALES
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        GuaranteeLibrary.CheckGuaranteeBankCardFields(DTNGARGuarantee);
        //Test Campos FIANZAS 
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        GuaranteeLibrary.CheckGuaranteeBondCardFields(DTNGARGuarantee);


        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //Test captura error ya existe fianza creada con el mismo numero
        LibrarySales.CreateCustomer(Customer);
        asserterror GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(BondExistsErrErr, ActualValue, IfErrorTxt);


    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure FieldEnabledEndorsementBankGuaranGurantee()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        BGExistsErr: label 'There is already a bank guarantee with the same No..', Comment = '"Ya existe un aval con el mismo Nº."';
        ActualValue: Text;
        IfErrorTxt: Text;
    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);


        //Test Campos AVALES
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        //Test Campos FIANZAS 
        asserterror GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(BGExistsErr, ActualValue, IfErrorTxt);


    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler')]
    procedure TestReportPostGurantees()
    var
        Vendor: record Vendor;
    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        LibraryPurchase.CreateVendor(Vendor);
        BankAccount.DeleteAll();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Vendor."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Vendor, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
    end;


    [Test]
    [HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler,PageHandlerGuarantees480')]
    procedure TestPageGuaranteeCardDimension()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";

    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard.Dimensions.Invoke();
        DTNGARGuranteeCard.Close();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler,PageHandlerGuarantees480')]
    procedure TestPageBondCardDimension()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
    begin
        // [Escenario] Inicializar escenario  
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard.Dimensions.Invoke();
        DTNGARBondCard.Close();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler,PageHandlerGuarantees456')]
    procedure TestPageGuaranteeCardAssisEdit()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";
    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard."No.".AssistEdit();
        DTNGARGuranteeCard.Close();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler,PageHandlerGuarantees456')]
    procedure TestPageBondCardAssisEdit()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
    begin

        // [Escenario] Inicializar escenario    
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard."No.".AssistEdit();
        DTNGARBondCard.Close();
    end;


    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    procedure PageSetupCard()
    var
        DTNGARUserSetupPage: TestPage "DTNGAR Guarantee Setup";
    begin

        // [Escenario] Inicializar escenario
        DTNGARSetup.DeleteAll(true);
        DTNGARSetup.Init();
        DTNGARSetup.Code := '';
        // [Ejecucion]
        DTNGARSetup.Validate("Pre Guarantee Required", true);

        // [Comprobacion]
        DTNGARSetup.DeleteAll(true);
        DTNGARUserSetupPage.OpenEdit();
        DTNGARUserSetupPage.GoToRecord(DTNGARSetup);
        DTNGARUserSetupPage.Close();
    end;



    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PageSetupCardtrue()
    var
        DTNGARUserSetupPage: TestPage "DTNGAR Guarantee Setup";

    begin

        // [Escenario] Inicializar escenario
        DTNGARSetup.DeleteAll(true);
        DTNGARSetup.Init();
        DTNGARSetup.Code := '';
        // [Ejecucion]
        DTNGARSetup.Validate("Pre Guarantee Required", true);

        // // [Comprobacion]
        DTNGARSetup.DeleteAll(true);
        DTNGARUserSetupPage.OpenEdit();
        DTNGARUserSetupPage.GoToRecord(DTNGARSetup);
        DTNGARUserSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    procedure PageSetupCardFalse()
    var
        DTNGARUserSetupPage: TestPage "DTNGAR Guarantee Setup";

    begin

        // [Escenario] Inicializar escenario
        DTNGARSetup.DeleteAll(true);
        DTNGARSetup.Init();
        DTNGARSetup.Code := '';
        // [Ejecucion]
        DTNGARSetup.Validate("Pre Guarantee Required", true);

        // // [Comprobacion]
        DTNGARSetup.DeleteAll(true);
        DTNGARUserSetupPage.OpenEdit();
        DTNGARUserSetupPage.GoToRecord(DTNGARSetup);
        DTNGARUserSetupPage.Close();
    end;

    [Test]
    //[HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    procedure PageSetupCardInsert()
    var
        SourceCodeRec: record "Source Code";
        DTNGARUserSetupPage: TestPage "DTNGAR Guarantee Setup";
    begin

        // [Escenario] Inicializar escenario
        SourceCodeRec.Init();
        DTNGARSetup.Init();

        // [Ejecucion]
        SourceCodeRec.DeleteAll(true);
        DTNGARSetup.DeleteAll(true);

        // // [Comprobacion]
        DTNGARSetup.DeleteAll(true);
        DTNGARUserSetupPage.OpenEdit();

        DTNGARUserSetupPage.GoToRecord(DTNGARSetup);
        DTNGARUserSetupPage.Close();
    end;




    [Test]
    procedure UserSetupTypePosition()
    var
        DTNGARUserSetupPage: Record "User Setup";
        Assert: Codeunit Assert;
        UserAlreadyAssociatedErr: Label 'The position type %1 has already have an associated user', comment = '"El tipo cargo %1 ya tiene un usuario asociado."';
        ActualValue: Text;
        ExpectedValue: Text;
        IfErrorTxt: Text;
    begin

        // [Escenario] Inicializar escenario
        DTNGARUserSetupPage.DeleteAll(true);
        // User Director
        DTNGARUserSetupPage.Init();
        DTNGARUserSetupPage."User ID" := 'Dir';
        DTNGARUserSetupPage.Validate("DTNGAR Position Type", DTNGARUserSetupPage."DTNGAR Position Type"::Director);
        DTNGARUserSetupPage.Validate("DTNGAR Name in Reports", libraryUtility.GenerateRandomText(80));
        DTNGARUserSetupPage.Validate("DTNGAR Position Name in Rep.", libraryUtility.GenerateRandomText(80));
        DTNGARUserSetupPage.Insert(true);
        Commit();
        // [Ejecucion]
        // User Director2
        DTNGARUserSetupPage.Init();
        DTNGARUserSetupPage."User ID" := 'Dir2';
        // [Comprobacion]
        asserterror DTNGARUserSetupPage.Validate("DTNGAR Position Type", DTNGARUserSetupPage."DTNGAR Position Type"::Director);
        DTNGARUserSetupPage.Validate("DTNGAR Name in Reports", libraryUtility.GenerateRandomText(80));
        DTNGARUserSetupPage.Validate("DTNGAR Position Name in Rep.", libraryUtility.GenerateRandomText(80));
        DTNGARUserSetupPage.Insert(true);

        ExpectedValue := StrSubstNo(UserAlreadyAssociatedErr, DTNGARUserSetupPage."DTNGAR Position Type"::Director);
        ActualValue := GetLastErrorText();//Capturar el error estandar
        IfErrorTxt := 'El texto del error no es el esperado';// Texto que queremos mostrar si no se cumple
        Assert.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    //[HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler')]
    procedure TestTableGuarantee3OnValidate()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bank Guarantee Card";
    begin
        // [Escenario] Inicializar escenario  
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]

        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard."Guaranteed Type".SetValue(DTNGARGuarantee.Type::Bond);
        DTNGARBondCard."Guaranteed Type".SetValue(DTNGARGuarantee.Type::"Bank Guarantee");
        DTNGARBondCard.Close();
    end;


    // MANEJAR VENTANAS AVALES
    [ModalPageHandler]
    procedure ModalPageHandler39(VAR GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure PageHandlerGuarantees480(var EditDimension: TestPage "Edit Dimension Set Entries");
    begin
        EditDimension.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PageHandlerGuarantees456(var EditSeries: TestPage "No. Series");
    begin
        EditSeries.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RequestPageHandlerPostGurantees(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        ActionType: Enum "DTNGAR PostTypeProcess";
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
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.OK().INVOKE();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure ModalPageHandler(VAR BankGuaranteeCard: TestPage "DTNGAR Bank Guarantee Card")
    begin
        BankGuaranteeCard.OK().INVOKE();
    end;

    [RequestPageHandler]
    procedure RequestPageHandler(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
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
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);//AML 
                    RequestPage.OK().INVOKE();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure JournalModalPageHandler39(VAR GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().INVOKE();
    end;


    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin
        Msg := 'OK';
    end;
    /*REPORT*/
    [RequestPageHandler]
    procedure PageHandlerGuaranteesReportNoteReturn(var RequestPage: TestRequestPage "DTNGAR Internal BG Return Note");
    begin
        RequestPage.Cancel().Invoke();

    end;

    [RequestPageHandler]
    procedure PageHandlerGuaranteesrConstitutedBG(var RequestPage: TestRequestPage "DTNGAR Const. Bank Guarantees");
    begin

        //RequestPage.PositionType.SetValue(DTNGARUserSetup."DTNGAR Position Type"::Director);
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;


    [RequestPageHandler]
    procedure PageHandlerGuaranteesReturnLetter(var RequestPage: TestRequestPage "DTNGAR BG Return Letter");
    begin

        //RequestPage.PositionType.SetValue(DTNGARUserSetup."DTNGAR Position Type"::Director);
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure PageHandlerGuaranteesDepositLetter(var RequestPage: TestRequestPage "DTNGAR BG Execution Letter");
    begin
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure PageHandlerGuaranteesExecutionLetter(var RequestPage: TestRequestPage "DTNGAR BG Execution Letter");
    begin
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;

    [Test]

    [HandlerFunctions('RequestPageHandlerPostGurantees,MessageHandler,PageHandlerGuaranteesReportNoteReturn')]
    procedure ReportPageGuaranteeCardReportNoteReturnCustomer()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";

    begin

        // [Escenario] Inicializar escenario   
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        Commit();


        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard."Internal Return Note".Invoke();
        DTNGARGuranteeCard.Close();
    end;


    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler,PageHandlerBondDepositLetter')]
    procedure ReportPageGuaranteeCardReportDepositLetter()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";
    begin

        // [Escenario] Inicializar escenario 
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        Commit();
        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard."Deposit Letter".Invoke();
        DTNGARGuranteeCard.Close();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler,PageHandlerGuaranteesExecutionLetter')]
    procedure ReportPageGuaranteeCardReportExecutionLetter()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";
    begin

        // [Escenario] Inicializar escenario 
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        // Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        Commit();
        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard."Execution Letter".Invoke();
        DTNGARGuranteeCard.Close();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler,PageHandlerGuaranteesReturnLetter')]
    procedure ReportPageGuaranteeCardReportReturnLetterCustomer()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";
    begin

        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        Commit();
        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard."Return Letter".Invoke();
        DTNGARGuranteeCard.Close();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,MessageHandler,PageHandlerGuaranteesrConstitutedBG')]
    procedure ReportPageGuaranteeCardReportBankGuaranteeConstitutionCustomer()
    var
        Customer: Record Customer;
        DTNGARGuranteeCard: TestPage "DTNGAR Bank Guarantee Card";
    begin

        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::"Bank Guarantee", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);

        Commit();
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        GuaranteeLibrary.RetunrGuarantee(DTNGARGuarantee);
        Commit();
        // [Comprobacion]
        DTNGARGuranteeCard.OpenEdit();
        DTNGARGuranteeCard.GoToRecord(DTNGARGuarantee);
        DTNGARGuranteeCard."Bank Guarantee Constitution".Invoke();
        DTNGARGuranteeCard.Close();
    end;




    //Report Bond
    [RequestPageHandler]
    procedure PageHandlerBondDepositLetter(var RequestPage: TestRequestPage "DTNGAR Deposit Letter");
    begin
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;


    [RequestPageHandler]
    procedure PageHandlerBondReturnWriting(var RequestPage: TestRequestPage "DTNGAR Guarantees Fin. Letter");
    begin
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;




    [RequestPageHandler]
    procedure PageHandlerBondReturnLetter(var RequestPage: TestRequestPage "DTNGAR Bond Return Letter");
    begin
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
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

    [RequestPageHandler]
    procedure RPHDepositPostBond(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        DTNGARAccountGroup: Record "DTNGAR Account Group";
        ActionType: Enum "DTNGAR PostTypeProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
    begin
        DTNGARAccountGroup.get(DTNGARGuarantee."Account Group");
        BankAccount.FindFirst();
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin

                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(-10000, -40000, 2));
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
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


    [RequestPageHandler]
    procedure PageHandlerBondSeizureLetter(var RequestPage: TestRequestPage "DTNGAR Bond Seizure Letter");
    begin
        //RequestPage.Preview().invoke();//Previous();
        RequestPage.Cancel().Invoke();
    end;


    [Test]
    [HandlerFunctions('ModalPageHandler39,JournalRPHPostGuarantee,MessageHandler,ConfirmHandler,PageHandlerBondDepositLetter')]

    procedure ReportPageBondCardReportDepositLetterCustomer()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
    begin

        // [Escenario] Inicializar escenario
        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        GuaranteeLibrary.CreateGuaranteeSetupBond(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        // [Condiciones] No hay


        // [Ejecucion]
        // GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        // GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        // Commit();
        // [Ejecucion]
        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();


        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard."Deposit Letter".Invoke();
        DTNGARBondCard.Close();
    end;



    [Test]
    [HandlerFunctions('ModalPageHandler39,JournalRPHPostGuarantee,PageHandlerBondSeizureLetter,MessageHandler,ConfirmHandler')]
    procedure ReportPageBondCardReportSeizurLetter()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
        LastBankEntry: Integer;
        LastCustLedgerEntry: Integer;
        LastDetCustLedEntry: Integer;

    begin

        // [Escenario] Inicializar escenario
        LibraryERM.CreateBankAccount(BankAccount);
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        GuaranteeLibrary.CreateGuaranteeSetupBond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay
        GuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);



        // [Ejecucion]
        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();

        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunRunGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();



        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard."Seizure Letter".Invoke();
        DTNGARBondCard.Close();
    end;


    [Test]
    [HandlerFunctions('ModalPageHandler39,JournalRPHPostGuarantee,PageHandlerBondReturnLetter,MessageHandler,ConfirmHandler')]
    procedure ReportPageBondCardReportReturnLette()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
        LastBankEntry: Integer;
        LastCustLedgerEntry: Integer;
        LastDetCustLedEntry: Integer;
    begin

        // [Escenario] Inicializar escenario
        LibraryERM.CreateBankAccount(BankAccount);
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        GuaranteeLibrary.CreateGuaranteeSetupBond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Deposited);
        Commit();
        // [Condiciones] No hay
        GuaranteeLibrary.InitLastLedgerEntries(LastLedgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);


        // [Ejecucion]
        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();

        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();



        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard."Return Letter".Invoke();
        DTNGARBondCard.Close();
    end;



    [Test]
    [HandlerFunctions('ModalPageHandler39,JournalRPHPostGuarantee,PageHandlerBondReturnWriting,MessageHandler,ConfirmHandler')]
    procedure ReportPageBondCardReportReturnWritingCustomer()
    var
        Customer: Record Customer;
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
    begin

        // [Escenario] Inicializar escenario
        LibraryERM.CreateBankAccount(BankAccount);
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        GuaranteeLibrary.CreateGuaranteeSetupBond(DTNGARSetup);
        GuaranteeLibrary.CreateGuaranteeSetupGuarantee(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();

        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();


        // [Comprobacion]
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);
        DTNGARBondCard."Return Writing".Invoke();
        DTNGARBondCard.Close();
    end;

    [Test]
    // PageHandlerBondDepositLetter
    [HandlerFunctions('ModalPageHandler39,JournalRPHPostGuarantee,MessageHandler,ConfirmHandler')]

    procedure ReportPageBondCardReportDepositLetterCustomerError()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        GuaranteedNoErr: Label 'Guaranteed No. must be filled in the guarantee.', Comment = '"Nº avalado debe estar definido en la garantía."';
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
        ActualValue: Text;
        IfErrorTxt: Text;
    begin

        // [Escenario] Inicializar escenario
        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        GuaranteeLibrary.CreateGuaranteeSetupBond(DTNGARSetup);
        GuaranteeLibrary.CheckGuaranteeSetupFields();
        GuaranteeLibrary.CreateUserSetup(DTNGARUserSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.DeleteJournalLine();
        GuaranteeLibrary.RunDepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.PostJournalLine();

        DTNGARGuarantee.Validate("Guaranteed No.", '');
        DTNGARGuarantee.Modify();
        Commit();
        DTNGARBondCard.OpenEdit();
        DTNGARBondCard.GoToRecord(DTNGARGuarantee);

        asserterror DTNGARBondCard."Deposit Letter".Invoke();
        // [Comprobacion]
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'El texto del error no es el esperado';
        Assert.AreEqual(GuaranteedNoErr, ActualValue, IfErrorTxt);
        DTNGARBondCard.Close();
    end;

}