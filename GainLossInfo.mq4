//+------------------------------------------------------------------+
//|                                                 GainLossInfo.mq4 |
//|                             Copyright © 2013-2022, EarnForex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013-2022, www.EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Gain-Loss-Info/"
#property version   "1.01"
#property strict

#property description "Shows percentage and point gain/loss for a candle."
#property description "Can calculate gain/loss compared either to the previous Close or to the current Open."

// The indicator uses only objects for display, but the line below is required for it to work.
#property indicator_chart_window

input double PercentageLimit = 1.0; // PercentageLimit - Will not display number if percentage gain/loss is below limit.
input int PointsLimit = 1000; // PointsLimit - Will not display number if points gain/loss is below limit.
// If true, will compare Close of the current candle to Close of the previous one. Otherwise compares current Close to current Open.
input bool CloseToClose = true;
input color DisplayLossColor = clrRed;
input color DisplayGainColor = clrLimeGreen;
input int DisplayDistance = 100; // DisplayDistance - Distance in points from High/Low to percentage display.
input int MaxBars = 100; // MaxBars: More bars - more objects - more lag and memory usage.
input string FontFace = "Verdana";
input int FontSize = 10;
input string ObjectPrefix = "GLI-";

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, ObjectPrefix, -1, OBJ_TEXT);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    // Redraw visible labels.
    if (id == CHARTEVENT_CHART_CHANGE) RedrawVisibleLabels();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    string perc, points, name;
    double start;

    int counted_bars = IndicatorCounted();
    if (counted_bars > 0) counted_bars--;
    int limit = Bars - counted_bars;
    if (limit > MaxBars) limit = MaxBars - 1;

    for (int i = 0; i <= limit; i++)
    {
        if ((CloseToClose) && (i + 1 < Bars)) start = Close[i + 1];
        else start = Open[i];

        name = ObjectPrefix + "Percent-" + TimeToStr(Time[i], TIME_DATE | TIME_MINUTES);
        ObjectDelete(name);
        if (((Close[i] - start) / start) * 100 >= PercentageLimit) // Gain percent display
        {
            perc = DoubleToStr(((Close[i] - start) / start) * 100, 1) + "%";
            ObjectCreate(name, OBJ_TEXT, 0, Time[i], High[i]);
            ObjectSetText(name, perc, FontSize, FontFace, DisplayGainColor);
            int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
            int first_bar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
            int last_bar = first_bar - visible_bars + 1;
            if ((i <= first_bar) && (i >= last_bar)) RedrawOneLabel(i, last_bar);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
        else if (((start - Close[i]) / start) * 100 >= PercentageLimit) // Loss percent display
        {
            perc = DoubleToStr(((start - Close[i]) / start) * 100, 1) + "%";
            ObjectCreate(name, OBJ_TEXT, 0, Time[i], High[i]);
            ObjectSetText(name, perc, FontSize, FontFace, DisplayLossColor);
            int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
            int first_bar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
            int last_bar = first_bar - visible_bars + 1;
            if ((i <= first_bar) && (i >= last_bar)) RedrawOneLabel(i, last_bar);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }

        name = ObjectPrefix + "Points-" + TimeToStr(Time[i], TIME_DATE | TIME_MINUTES);
        ObjectDelete(name);
        if ((Close[i] - start) / Point >= PointsLimit) // Gain points display
        {
            points = DoubleToStr((Close[i] - start) / Point, 0);
            ObjectCreate(name, OBJ_TEXT, 0, Time[i], Low[i]);
            ObjectSetText(name, points, FontSize, FontFace, DisplayGainColor);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
        else if ((start - Close[i]) / Point >= PointsLimit) // Loss points display
        {
            points = DoubleToStr((start - Close[i]) / Point, 0);
            ObjectCreate(name, OBJ_TEXT, 0, Time[i], Low[i]);
            ObjectSetText(name, points, FontSize, FontFace, DisplayLossColor);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
    }

    return rates_total;
}

// Required only for labels above High.
void RedrawVisibleLabels()
{
   int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   int first_bar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
   int last_bar = first_bar - visible_bars + 1;
   
   // Process all bars on the current screen.
   for (int i = first_bar; i >= last_bar; i--) RedrawOneLabel(i, last_bar);
}

void RedrawOneLabel(const int i, const int last_bar)
{
   int x, y, cw;
   uint w, h;
   datetime t;
   double p;
   string length, name;

   name = GenerateObjectName("Percent-", Time[i]);
   if (ObjectFind(0, name) == -1) return;
   // Needed only for y; x is used as a dummy.
   ChartTimePriceToXY(0, 0, Time[last_bar], High[i], x, y);
   // Get the height of the text based on font and its size. Negative because OS-dependent, *10 because set in 1/10 of pt.
   TextSetFont(FontFace, FontSize * -10);
   length = DoubleToString(MathRound((High[i] - MathMax(Open[i], Close[i])) / Point), 0);
   TextGetSize(length, w, h);
   ChartXYToTimePrice(0, x, y - h - 2, cw, t, p);
   ObjectSetDouble(0, name, OBJPROP_PRICE, p);
}

string GenerateObjectName(const string prefix, const datetime time)
{
   return ObjectPrefix + prefix + TimeToStr(time, TIME_DATE | TIME_MINUTES);
}
//+------------------------------------------------------------------+