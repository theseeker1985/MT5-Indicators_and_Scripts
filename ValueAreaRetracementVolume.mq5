//+------------------------------------------------------------------+
//|                      Value Area Retracement Volume               |
//|                         Copyright 2025, Richard                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.metaquotes.net/"
#property version   "1.10"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

// Input parameters
input int ValueAreaPercentage = 70;      // Value area percentage (typically 70%)
input int ProfileResolution = 50;        // Number of price levels for volume profile
input ENUM_TIMEFRAMES ProfileTimeframe = PERIOD_D1; // Timeframe for volume profile
input bool ShowVisualElements = true;    // Show visual elements on chart

// Buffers for drawing
double POCBuffer[];
double VAHighBuffer[];
double VALowBuffer[];
double ProfileHighBuffer[];
double ProfileLowBuffer[];
double SignalBuffer[];

// Variables to store profile levels
double poc, vaHigh, vaLow, profileHigh, profileLow;
datetime lastCalculationTime;
int profileBarsToCalculate = 1; // Number of bars to calculate profile for

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize buffers
   SetIndexBuffer(0, POCBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, VAHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, VALowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, ProfileHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, ProfileLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, SignalBuffer, INDICATOR_DATA);
   
   // Set drawing styles
   ArraySetAsSeries(POCBuffer, true);
   ArraySetAsSeries(VAHighBuffer, true);
   ArraySetAsSeries(VALowBuffer, true);
   ArraySetAsSeries(ProfileHighBuffer, true);
   ArraySetAsSeries(ProfileLowBuffer, true);
   ArraySetAsSeries(SignalBuffer, true);
   
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   // Set plot properties
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrBlue);
   PlotIndexSetString(0, PLOT_LABEL, "POC");
   
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrGreen);
   PlotIndexSetString(1, PLOT_LABEL, "VA High");
   
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrGreen);
   PlotIndexSetString(2, PLOT_LABEL, "VA Low");
   
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(3, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetString(3, PLOT_LABEL, "Profile High");
   
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(4, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetString(4, PLOT_LABEL, "Profile Low");
   
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(5, PLOT_ARROW, 233);
   PlotIndexSetInteger(5, PLOT_ARROW_SHIFT, -10);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, clrGold);
   PlotIndexSetString(5, PLOT_LABEL, "Signal");
   
   lastCalculationTime = 0;
   
   // Adjust number of bars to calculate based on timeframe
   if(ProfileTimeframe == PERIOD_MN1) profileBarsToCalculate = 12; // Approximate months in a year
   else if(ProfileTimeframe == PERIOD_W1) profileBarsToCalculate = 4; // Weeks in a month
   else profileBarsToCalculate = 1; // For daily and lower timeframes
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Calculate volume profile for specified timeframe                 |
//+------------------------------------------------------------------+
void CalculateVolumeProfile(const datetime startTime, const datetime endTime)
{
   double priceLevels[];
   long volumes[];
   ArrayResize(priceLevels, ProfileResolution);
   ArrayResize(volumes, ProfileResolution);
   ArrayInitialize(volumes, 0);
   
   // Get profile period high and low
   double periodHigh = iHigh(_Symbol, ProfileTimeframe, 1);
   double periodLow = iLow(_Symbol, ProfileTimeframe, 1);
   double range = periodHigh - periodLow;
   double step = range / ProfileResolution;
   
   // Initialize price levels
   for(int i = 0; i < ProfileResolution; i++)
   {
      priceLevels[i] = periodLow + i * step;
   }
   
   // Aggregate volumes at each price level using M1 data for precision
   int m1Bars = iBars(_Symbol, PERIOD_M1);
   for(int i = 0; i < m1Bars; i++)
   {
      datetime time = iTime(_Symbol, PERIOD_M1, i);
      if(time >= startTime && time <= endTime)
      {
         double high = iHigh(_Symbol, PERIOD_M1, i);
         double low = iLow(_Symbol, PERIOD_M1, i);
         long volume = iVolume(_Symbol, PERIOD_M1, i);
         
         for(int j = 0; j < ProfileResolution; j++)
         {
            if(priceLevels[j] >= low && priceLevels[j] <= high)
            {
               volumes[j] += volume;
            }
         }
      }
   }
   
   // Find POC (price with highest volume)
   long maxVolume = 0;
   int pocIndex = 0;
   for(int i = 0; i < ProfileResolution; i++)
   {
      if(volumes[i] > maxVolume)
      {
         maxVolume = volumes[i];
         pocIndex = i;
      }
   }
   poc = priceLevels[pocIndex];
   
   // Find profile high and low (first and last prices with volume)
   profileHigh = periodHigh;
   profileLow = periodLow;
   
   // Calculate total volume and value area volume
   long totalVolume = 0;
   for(int i = 0; i < ProfileResolution; i++) totalVolume += volumes[i];
   long valueAreaVolume = totalVolume * ValueAreaPercentage / 100;
   
   // Find value area (70% of volume around POC)
   long currentVAVolume = 0;
   int vaHighIndex = pocIndex;
   int vaLowIndex = pocIndex;
   
   while(currentVAVolume < valueAreaVolume)
   {
      // Expand the value area upwards first
      if(vaHighIndex < ProfileResolution - 1)
      {
         vaHighIndex++;
         currentVAVolume += volumes[vaHighIndex];
         if(currentVAVolume >= valueAreaVolume) break;
      }
      
      // Then expand downwards
      if(vaLowIndex > 0)
      {
         vaLowIndex--;
         currentVAVolume += volumes[vaLowIndex];
      }
      
      // If we've reached the profile boundaries
      if(vaHighIndex >= ProfileResolution - 1 && vaLowIndex <= 0)
      {
         break;
      }
   }
   
   vaHigh = priceLevels[vaHighIndex];
   vaLow = priceLevels[vaLowIndex];
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
   // Check if we have enough data
   if(rates_total < 2) return(0);
   
   // Only calculate when new bar starts on the profile timeframe
   datetime currentProfileTime = iTime(_Symbol, ProfileTimeframe, 0);
   if(currentProfileTime == lastCalculationTime) return(rates_total);
   lastCalculationTime = currentProfileTime;
   
   // Get previous profile period start and end time
   datetime profileStart = iTime(_Symbol, ProfileTimeframe, 1);
   datetime profileEnd = profileStart + PeriodSeconds(ProfileTimeframe) - 1;
   
   // Calculate the profile
   CalculateVolumeProfile(profileStart, profileEnd);
   
   // Get current period open price (on the chart timeframe)
   double currentOpen = iOpen(_Symbol, _Period, 0);
   
   // Initialize buffers
   ArrayInitialize(POCBuffer, EMPTY_VALUE);
   ArrayInitialize(VAHighBuffer, EMPTY_VALUE);
   ArrayInitialize(VALowBuffer, EMPTY_VALUE);
   ArrayInitialize(ProfileHighBuffer, EMPTY_VALUE);
   ArrayInitialize(ProfileLowBuffer, EMPTY_VALUE);
   ArrayInitialize(SignalBuffer, EMPTY_VALUE);
   
   // Fill buffers with profile levels
   for(int i = 0; i < rates_total; i++)
   {
      POCBuffer[i] = poc;
      VAHighBuffer[i] = vaHigh;
      VALowBuffer[i] = vaLow;
      ProfileHighBuffer[i] = profileHigh;
      ProfileLowBuffer[i] = profileLow;
   }
   
   // Generate trading signals based on current open relative to profile
   string timeframeStr = EnumToString(ProfileTimeframe);
   StringReplace(timeframeStr, "PERIOD_", "");
   
   if(currentOpen > vaLow && currentOpen < vaHigh)
   {
      // Open within value area - no clear signal
      Comment(timeframeStr + " Profile: Open within Value Area. No clear signal.\n" +
              "POC: ", poc, " | VA High: ", vaHigh, " | VA Low: ", vaLow);
   }
   else if(currentOpen > vaHigh && currentOpen < profileHigh)
   {
      // Open above value area but below profile high - look for buy on retracement to POC
      Comment(timeframeStr + " Profile: Buy opportunity on retracement to POC: ", poc, "\n" +
              "VA High: ", vaHigh, " | Profile High: ", profileHigh);
      
      // Mark POC level with signal
      for(int i = 0; i < rates_total; i++)
      {
         if(MathAbs(close[i] - poc) < 0.5 * _Point)
         {
            SignalBuffer[i] = poc;
         }
      }
   }
   else if(currentOpen < vaLow && currentOpen > profileLow)
   {
      // Open below value area but above profile low - look for sell on retracement to POC
      Comment(timeframeStr + " Profile: Sell opportunity on retracement to POC: ", poc, "\n" +
              "VA Low: ", vaLow, " | Profile Low: ", profileLow);
      
      // Mark POC level with signal
      for(int i = 0; i < rates_total; i++)
      {
         if(MathAbs(close[i] - poc) < 0.5 * _Point)
         {
            SignalBuffer[i] = poc;
         }
      }
   }
   else if(currentOpen > profileHigh)
   {
      // Open above profile high - potential breakout to the upside
      Comment(timeframeStr + " Profile: Potential upside breakout - open above profile high: ", profileHigh);
   }
   else if(currentOpen < profileLow)
   {
      // Open below profile low - potential breakout to the downside
      Comment(timeframeStr + " Profile: Potential downside breakout - open below profile low: ", profileLow);
   }
   
   return(rates_total);
}