//+------------------------------------------------------------------+
//|                Multi Fibonacci Retracement Indicator             |
//|                       Copyright 2025, Richard                    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Richard"
#property version   "1.2"
#property strict
#property indicator_chart_window

//--- Input Parameters
input int    FractalPeriod = 2;        // Swing detection sensitivity (Try 2 for 15m or 5 for 1hr)
input color  BullishColor  = clrGreen;  // Bullish color (green)
input color  BearishColor  = clrRed;    // Bearish color (red)
input int    LabelFontSize = 8;
input bool   ShowDebugInfo = true;     // All logs are bundles - add whatever you want
input bool   StrictSwingConfirmation = true; // Indicator checks that the close confirms the swing (see documentation)
input int    MaxLookbackBars = 50;     // 50 on 15m = 12.5hrs
input int    MaxFibsToDraw = 4;        // Maximum number of Fibs to draw
input bool   DrawTrendLines = true;     // Point A/B trendlines are drawn

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   ObjectsDeleteAll(0, 0, -1);
   Print("Multi-Fibonacci Indicator initialized");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
   static datetime lastBarTime;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   
   if(lastBarTime != currentBarTime)
   {
      lastBarTime = currentBarTime;
      DetectSwingsAndDrawFibs();
   }
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Core Fibonacci Calculations                                      |
//+------------------------------------------------------------------+
void DetectSwingsAndDrawFibs()
{
    // Delete previous Fibs and trendlines
    ObjectsDeleteAll(0, "FIB_*");
    if(DrawTrendLines) ObjectsDeleteAll(0, "TREND_*");
    
    // Find all swing highs and lows within lookback
    double swingHighs[]; datetime swingHighTimes[];
    double swingLows[]; datetime swingLowTimes[];
    
    int highCount = FindAllSwingHighs(FractalPeriod, swingHighs, swingHighTimes);
    int lowCount = FindAllSwingLows(FractalPeriod, swingLows, swingLowTimes);
    
    double currentClose = iClose(_Symbol, _Period, 0);
    int fibsDrawn = 0;
    
    // Draw Bullish Fibs (Low -> High)
    for(int i = lowCount-1; i >= 0 && fibsDrawn < MaxFibsToDraw; i--)
    {
        for(int j = highCount-1; j >= 0 && fibsDrawn < MaxFibsToDraw; j--)
        {
            if(swingHighs[j] > swingLows[i] && swingHighTimes[j] > swingLowTimes[i])
            {
                double range = swingHighs[j] - swingLows[i];
                double level618 = swingHighs[j] - (range * 0.618);
                double level1618 = swingLows[i] + (range * 1.618);
                
                string prefix = "FIB_BULL_" + IntegerToString(fibsDrawn);
                DrawFibLevel(prefix + "_LOW", swingLows[i], "L: ", BullishColor, STYLE_SOLID, swingLowTimes[i]);
                DrawFibLevel(prefix + "_HIGH", swingHighs[j], "H: ", BullishColor, STYLE_SOLID, swingHighTimes[j]);
                DrawFibLevel(prefix + "_618", level618, "61.8%: ", BullishColor, STYLE_DASH, TimeCurrent());
                DrawFibLevel(prefix + "_1618", level1618, "161.8%: ", BullishColor, STYLE_DASHDOT, TimeCurrent());
                
                // Draw trendline for bullish fib
                if(DrawTrendLines)
                {
                    string trendName = "TREND_BULL_" + IntegerToString(fibsDrawn);
                    DrawTrendLine(trendName, swingLowTimes[i], swingLows[i], swingHighTimes[j], swingHighs[j], BullishColor);
                }
                
                fibsDrawn++;
                if(ShowDebugInfo) Print("Drawn Bullish Fib #", fibsDrawn, " Low:", swingLows[i], " High:", swingHighs[j]);
            }
        }
    }
    
    fibsDrawn = 0;
    // Draw Bearish Fibs (High -> Low)
    for(int i = highCount-1; i >= 0 && fibsDrawn < MaxFibsToDraw; i--)
    {
        for(int j = lowCount-1; j >= 0 && fibsDrawn < MaxFibsToDraw; j--)
        {
            if(swingLows[j] < swingHighs[i] && swingLowTimes[j] > swingHighTimes[i])
            {
                double range = swingHighs[i] - swingLows[j];
                double level618 = swingHighs[i] - (range * 0.618);
                double level1618 = swingHighs[i] - (range * 1.618);
                
                string prefix = "FIB_BEAR_" + IntegerToString(fibsDrawn);
                DrawFibLevel(prefix + "_HIGH", swingHighs[i], "H: ", BearishColor, STYLE_SOLID, swingHighTimes[i]);
                DrawFibLevel(prefix + "_LOW", swingLows[j], "L: ", BearishColor, STYLE_SOLID, swingLowTimes[j]);
                DrawFibLevel(prefix + "_618", level618, "61.8%: ", BearishColor, STYLE_DASH, TimeCurrent());
                DrawFibLevel(prefix + "_1618", level1618, "161.8%: ", BearishColor, STYLE_DASHDOT, TimeCurrent());
                
                // Draw trendline for bearish fib
                if(DrawTrendLines)
                {
                    string trendName = "TREND_BEAR_" + IntegerToString(fibsDrawn);
                    DrawTrendLine(trendName, swingHighTimes[i], swingHighs[i], swingLowTimes[j], swingLows[j], BearishColor);
                }
                
                fibsDrawn++;
                if(ShowDebugInfo) Print("Drawn Bearish Fib #", fibsDrawn, " High:", swingHighs[i], " Low:", swingLows[j]);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Draws a trendline between two points                             |
//+------------------------------------------------------------------+
void DrawTrendLine(string name, datetime time1, double price1, datetime time2, double price2, color clr)
{
    if(!ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2))
    {
        if(ShowDebugInfo) Print("Error creating trendline: ", GetLastError());
        return;
    }
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);  // Thin line
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_RAY, false);  // Not extending to infinity
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);  // Draw in background
}

//+------------------------------------------------------------------+
//| Finds all visible swing highs with timestamps                    |
//+------------------------------------------------------------------+
int FindAllSwingHighs(int period, double &highs[], datetime &highTimes[])
{
    int totalBars = Bars(_Symbol, _Period);
    int lookback = MathMin(MaxLookbackBars, totalBars - period - 1);
    int count = 0;
    
    ArrayResize(highs, lookback);
    ArrayResize(highTimes, lookback);
    
    for(int i = period; i < lookback; i++)
    {
        bool isHigh = true;
        double currentHigh = iHigh(_Symbol, _Period, i);
        datetime currentTime = iTime(_Symbol, _Period, i);
        
        for(int j = 1; j <= period; j++)
        {
            if(iHigh(_Symbol, _Period, i-j) >= currentHigh || 
               iHigh(_Symbol, _Period, i+j) >= currentHigh)
            {
                isHigh = false;
                break;
            }
        }
        
        if(isHigh && (!StrictSwingConfirmation || (iClose(_Symbol, _Period, i) > iClose(_Symbol, _Period, i+1))))
        {
            highs[count] = currentHigh;
            highTimes[count] = currentTime;
            count++;
        }
    }
    
    ArrayResize(highs, count);
    ArrayResize(highTimes, count);
    return count;
}

//+------------------------------------------------------------------+
//| Finds all visible swing lows with timestamps                     |
//+------------------------------------------------------------------+
int FindAllSwingLows(int period, double &lows[], datetime &lowTimes[])
{
    int totalBars = Bars(_Symbol, _Period);
    int lookback = MathMin(MaxLookbackBars, totalBars - period - 1);
    int count = 0;
    
    ArrayResize(lows, lookback);
    ArrayResize(lowTimes, lookback);
    
    for(int i = period; i < lookback; i++)
    {
        bool isLow = true;
        double currentLow = iLow(_Symbol, _Period, i);
        datetime currentTime = iTime(_Symbol, _Period, i);
        
        for(int j = 1; j <= period; j++)
        {
            if(iLow(_Symbol, _Period, i-j) <= currentLow || 
               iLow(_Symbol, _Period, i+j) <= currentLow)
            {
                isLow = false;
                break;
            }
        }
        
        if(isLow && (!StrictSwingConfirmation || (iClose(_Symbol, _Period, i) < iClose(_Symbol, _Period, i+1))))
        {
            lows[count] = currentLow;
            lowTimes[count] = currentTime;
            count++;
        }
    }
    
    ArrayResize(lows, count);
    ArrayResize(lowTimes, count);
    return count;
}

//+------------------------------------------------------------------+
//| Enhanced Drawing function with time anchoring                    |
//+------------------------------------------------------------------+
void DrawFibLevel(string name, double price, string label, color clr, ENUM_LINE_STYLE style, datetime anchorTime)
{
   // Create horizontal line
   if(!ObjectCreate(0, name+"_LINE", OBJ_HLINE, 0, 0, price))
   {
      if(ShowDebugInfo) Print("Error creating line: ", GetLastError());
      return;
   }
   
   ObjectSetInteger(0, name+"_LINE", OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name+"_LINE", OBJPROP_WIDTH, 1);  // Thin line
   ObjectSetInteger(0, name+"_LINE", OBJPROP_STYLE, style);
   ObjectSetInteger(0, name+"_LINE", OBJPROP_SELECTABLE, false);
   
   // Create text label anchored to the swing point
   if(!ObjectCreate(0, name+"_LABEL", OBJ_TEXT, 0, anchorTime, price))
   {
      if(ShowDebugInfo) Print("Error creating label: ", GetLastError());
      return;
   }
   
   ObjectSetString(0, name+"_LABEL", OBJPROP_TEXT, label + DoubleToString(price, _Digits));
   ObjectSetInteger(0, name+"_LABEL", OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name+"_LABEL", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name+"_LABEL", OBJPROP_FONTSIZE, LabelFontSize);
   ObjectSetInteger(0, name+"_LABEL", OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
