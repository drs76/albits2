/// <summary>
/// Codeunit PTEAPIHelper (ID 50100).
/// test codeunit for playing about with API's
/// </summary>
codeunit 50100 PTEAPIHelper
{

    trigger OnRun()
    var
        Response: Text;
    begin
        SendPayload('https://wttr.in/', 'Edinburgh', 'GET', Response);
    end;

    /// <summary>
    /// SendPayload.
    /// </summary>
    /// <param name="JsonContent">JsonObject.</param>
    /// <param name="BaseUrl">Text.</param>
    /// <param name="Service">Text.</param>
    /// <param name="Method">Text.</param>
    /// <param name="ResponseText">VAR Text.</param>
    /// <returns>Return variable ReturnValue of type Boolean.</returns>
    procedure SendPayload(JsonContent: JsonObject; BaseUrl: Text; Service: Text; Method: Text; var ResponseText: Text) ReturnValue: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        Request: HttpRequestMessage;
        WriteStream: OutStream;
        Token: Text;
    begin
        CreateRequest(Request, Method, CombineUrl(BaseUrl, Service));

        // add content        
        CreateContent(Request, JsonContent);

        ResponseText := SendRequest(Request, Token);
        if StrLen(ResponseText) = 0 then
            exit;

        TempBlob.CreateOutStream(WriteStream);
        WriteStream.WriteText(ResponseText);
        ReturnValue := true;
    end;

    /// <summary>
    /// SendPayload.
    /// </summary>
    /// <param name="BaseUrl">Text.</param>
    /// <param name="Service">Text.</param>
    /// <param name="Method">Text.</param>
    /// <param name="ResponseText">VAR Text.</param>
    /// <returns>Return variable ReturnValue of type Boolean.</returns>
    procedure SendPayload(BaseUrl: Text; Service: Text; Method: Text; var ResponseText: Text) ReturnValue: Boolean
    var
        EmptyContent: JsonObject;
    begin
        exit(SendPayload(EmptyContent, BaseUrl, Service, Method, ResponseText));
    end;

    /// <summary>
    /// CreateRequest.
    /// </summary>
    /// <param name="Request">VAR HttpRequestMessage.</param>
    local procedure CreateRequest(var Request: HttpRequestMessage; Method: Text; Url: Text)
    begin
        Request.SetRequestUri(Url);
        Request.Method := Method;
    end;

    /// <summary>
    /// CreateContent.
    /// </summary>
    /// <param name="Request">VAR HttpRequestMessage.</param>
    /// <param name="RequestObject">JsonObject.</param>
    local procedure CreateContent(var Request: HttpRequestMessage; RequestObject: JsonObject)
    var
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        ContentAsText: Text;
        ContentTypeLbl: Label 'Content-Type';
        ContentTypeValueLbl: Label 'application/json';
    begin
        if RequestObject.Values().Count() = 0 then
            exit;

        RequestObject.WriteTo(ContentAsText);
        Content.WriteFrom(ContentAsText);

        Content.GetHeaders(ContentHeaders);

        ContentHeaders.Clear();
        ContentHeaders.Add(ContentTypeLbl, ContentTypeValueLbl);
        Request.Content := Content;
    end;

    /// <summary>
    /// SendRequest.
    /// </summary>
    /// <param name="Request">HttpRequestMessage.</param>
    /// <param name="Token">Text.</param>
    /// <returns>Return variable ReturnValue of type Text.</returns>
    local procedure SendRequest(Request: HttpRequestMessage; Token: Text) ReturnValue: Text;
    var
        WebClient: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        AuthTxt: Label 'Bearer %1', Comment = '%1 is Authorization Token';
        AuthLbl: Label 'Authorization';
        ErrorMessageLbl: Label 'Request Status: %1', Comment = '%1 is Response Text';
    begin
        if StrLen(Token) > 0 then
            WebClient.DefaultRequestHeaders().Add(AuthLbl, StrSubstNo(AuthTxt, Token));

        if WebClient.Send(Request, Response) then
            Response.Content().ReadAs(ResponseText);

        if Response.IsSuccessStatusCode() then
            Response.Content().ReadAs(ReturnValue)
        else
            if Response.HttpStatusCode <> 404 then // 404 return blank, record not found
                Error(ErrorMessageLbl, ResponseText);
    end;

    /// <summary>
    /// GetMagentoToken.
    /// </summary>
    // /// <returns>Return variable ResponseTxt of type Text[100].</returns>
    // procedure GetMagentoToken() ResponseTxt: Text[100];
    // var
    //     MagentoLinkSetup: Record PTEMagentoLinkSetup;
    //     MagentoLinkRequestParam: Record PTEMagentoLinkRequestParameter;
    //     JsonBody: JsonObject;
    //     ServiceTxt: Label 'integration/admin/token';
    //     UsernameLbl: Label 'username';
    //     PassswordLbl: Label 'password';
    //     InvalidTokenErr: Label 'Magetno returned an invalid Token';
    //     CallerLbl: Label 'GetToken';
    //     QuoteTxt: Label '"';
    // begin
    //     MagentoLinkSetup.Get();

    //     MagentoLinkRequestParam.SetRequest(MagentoLinkRequestParam.Method::POST, ServiceTxt, CallerLbl);

    //     JsonBody.Add(UsernameLbl, MagentoLinkSetup.MagentoUser);
    //     JsonBody.Add(PassswordLbl, MagentoLinkSetup.MagentoPassword);

    //     if not SendPayload(JsonBody, MagentoLinkRequestParam) then
    //         Error(InvalidTokenErr);

    //     ResponseTxt := CopyStr(MagentoLinkRequestParam.GetResponseText(), 1, MaxStrLen(ResponseTxt));
    //     ResponseTxt := DelChr(ResponseTxt, '=', QuoteTxt); // remove quotes ""
    // end;


    /// <summary>
    /// CombineUrl.
    /// </summary>
    /// <param name="BaseUrl">Text.</param>
    /// <param name="Service">Text.</param>
    /// <returns>Return value of type Text.</returns>
    local procedure CombineUrl(BaseUrl: Text; Service: Text): Text;
    var
        UrlFormatTxt: Label '%1%2', Comment = '%1 is Base Url, %2 is Service';
        FwdSlashTxt: Label '/';
    begin
        case true of
            Format(BaseUrl).EndsWith(FwdSlashTxt):
                if Service.StartsWith(FwdSlashTxt) then
                    exit(StrSubstNo(UrlFormatTxt, BaseUrl, CopyStr(Service, 2, StrLen(Service))))
                else
                    exit(StrSubStno(UrlFormatTxt, BaseUrl, Service));
            Format(Service).StartsWith(FwdSlashTxt):
                exit(StrSubStno(UrlFormatTxt, BaseUrl, Service));
            else
                exit(StrSubStno(UrlFormatTxt, StrSubStno(UrlFormatTxt, BaseUrl, FwdSlashTxt), Service));
        end;
    end;
}
