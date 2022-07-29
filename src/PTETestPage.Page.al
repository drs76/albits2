/// <summary>
/// Page PTETestPage (ID 50100).
/// Page to launch tests from.
/// </summary>
page 50100 PTETestPage
{
    Caption = 'Test Bench Page';
    ApplicationArea = All;
    UsageCategory = Administration;
    PageType = Card;

    layout
    {
        area(Content)
        {
            group(API)
            {
                Caption = 'API Helper';

                usercontrol(WebViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    var
                        WeatherHtml: Text;
                        HtmlContentLbl: Label '<pre>%1</pre>', Comment = '%1 = message content';
                    begin
                        WeatherHtml := GetTheWeather();
                        CurrPage.WebViewer.SetContent(StrSubstNo(HtmlContentLbl, WeatherHtml));
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestAPI)
            {
                ApplicationArea = All;
                Caption = 'API';
                ToolTip = 'Test API Helper';
                Image = Web;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                RunObject = codeunit PTEAPIHelper;
            }
        }
    }

    /// <summary>
    /// GetTheWeather.
    /// Get the weather from wttr.io, get the content from the <PRE></PRE> tags.
    /// </summary>
    /// <returns>Return variable ReturnValue of type Text.</returns>
    local procedure GetTheWeather() ReturnValue: Text
    var
        Matches: Record Matches;
        RegexOpt: Record "Regex Options";
        APIHelper: Codeunit PTEAPIHelper;
        Regex: Codeunit Regex;
        Response: Text;
        WeatherUrlTxt: Label 'https://wttr.in/';
        LocationTxt: Label 'Edinburgh';
        MatchRehExpLbl: Label '<PRE>(.|\n)*?<\/PRE>';
    begin
        if not APIHelper.SendPayload(WeatherUrlTxt, LocationTxt, 'GET', Response) then
            exit;

        // get the weather content, this is in the <PRE> tag on the html page returned.
        RegexOpt.Init();
        RegexOpt.IgnoreCase := true;
        RegexOpt.Insert(true);

        Regex.Match(Response, MatchRehExpLbl, 0, RegexOpt, Matches);
        Message(Format(Matches.Count()));
        if not Matches.FindFirst() then
            exit;

        ReturnValue := Matches.ReadValue();
    end;
}
