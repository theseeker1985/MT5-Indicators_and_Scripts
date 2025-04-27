//+------------------------------------------------------------------+
//|                                 TickVolumeHeatmap.mq5            |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.metaquotes.net/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_BARS
#property indicator_color1  clrBlue,clrDodgerBlue,clrAqua,clrLimeGreen,clrGreenYellow,clrYellow,clrOrange,clrRed,clrDarkRed
#property indicator_width1  5

// Input parameters
input int       BarsToShow = 200;       // Number of bars to display
input double    Opacity    = 0.7;       // Heatmap opacity (0.1-1.0)

// Buffers
double          VolumeBuffer[];
double          ColorBuffer[];
double          MaxVolume;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set indicator properties
   SetIndexBuffer(0, VolumeBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ColorBuffer, INDICATOR_COLOR_INDEX);
   
   // Set empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   
   // Set visualization
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_BARS);
   PlotIndexSetString(0, PLOT_LABEL, "Volume Heatmap");
   
   IndicatorSetString(INDICATOR_SHORTNAME, "Tick Volume Heatmap");
   IndicatorSetInteger(INDICATOR_DIGITS, 0);
   
   // Initialize max volume
   MaxVolume = 1; // Start with 1 to avoid division by zero
   
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
   // Check if we have enough data
   if(rates_total < BarsToShow || ArraySize(tick_volume) < BarsToShow)
      return(0);
      
   // Set starting position
   int start = (prev_calculated == 0) ? 0 : prev_calculated - 1;
   
   // Find maximum volume for normalization
   if(prev_calculated == 0)
   {
      MaxVolume = 1;
      for(int i = 0; i < BarsToShow; i++)
      {
         if(i >= ArraySize(tick_volume)) break;
         if((double)tick_volume[i] > MaxVolume)
            MaxVolume = (double)tick_volume[i];
      }
   }
   else
   {
      // Check if new bar has higher volume
      if(rates_total > 0 && (double)tick_volume[rates_total-1] > MaxVolume)
         MaxVolume = (double)tick_volume[rates_total-1];
   }
   
   // Calculate heatmap
   for(int i = start; i < BarsToShow; i++)
   {
      if(i >= rates_total) break;
      
      VolumeBuffer[i] = (double)tick_volume[i];
      ColorBuffer[i] = GetColorIndex((double)tick_volume[i], MaxVolume);
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Get color index based on volume intensity                        |
//+------------------------------------------------------------------+
int GetColorIndex(double volume, double maxVol)
{
   // Normalize volume to 0-8 range for our 9 colors
   double normalized = volume / maxVol * 8.0;
   return (int)MathRound(normalized);
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                 const long &lparam,
                 const double &dparam,
                 const string &sparam)
{
   // Redraw heatmap when chart changes
   if(id == CHARTEVENT_CHART_CHANGE)
      ChartRedraw();
}