//+------------------------------------------------------------------+
//| Volume Data Checker                                              |
//| Checks if broker provides real volume data                       |
//+------------------------------------------------------------------+
#property copyright "Volume Data Checker"
#property version   "1.00"
#property strict
#property script_show_inputs

input int BarsToCheck = 1000;    // Number of bars to analyze
input bool ShowDetails = true;  // Show detailed comparison

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    int tickVolumeCount = 0;
    int realVolumeCount = 0;
    int discrepancyCount = 0;
    
    Print("=== Volume Data Checker ===");
    Print("Checking ", BarsToCheck, " bars...");
    
    for(int i=1; i<=BarsToCheck && !IsStopped(); i++)
    {
        long tickVol = iTickVolume(Symbol(), Period(), i);
        long realVol = iVolume(Symbol(), Period(), i);
        
        if(ShowDetails)
            Print("Bar ", i, ": Tick Volume=", tickVol, " | Real Volume=", realVol);
        
        if(tickVol > 0) tickVolumeCount++;
        if(realVol > 0) realVolumeCount++;
        if(tickVol != realVol) discrepancyCount++;
    }
    
    // Analysis results
    double matchPercentage = 100.0 - (100.0 * discrepancyCount/BarsToCheck);
    
    Print("\n=== Results ===");
    Print("Bars with tick volume data: ", tickVolumeCount, "/", BarsToCheck);
    Print("Bars with real volume data: ", realVolumeCount, "/", BarsToCheck);
    Print("Volume discrepancies found: ", discrepancyCount);
    Print("Data match percentage: ", DoubleToString(matchPercentage, 2), "%");
    
    if(matchPercentage > 98.0)
    {
        Print("\nCONCLUSION: This broker appears to be providing ONLY tick volume");
        Print("(Real volume data matches tick volume exactly)");
    }
    else if(matchPercentage < 2.0)
    {
        Print("\nCONCLUSION: This broker provides REAL volume data");
        Print("(Real volume differs significantly from tick volume)");
    }
    else
    {
        Print("\nCONCLUSION: Mixed or unclear volume data");
        Print("Some real volume data may be available, but not consistently");
    }
    
    Print("\nNote: Most Forex brokers only provide tick volume data.");
    Print("Real volume data would typically show significant differences");
    Print("from tick volume, especially on higher timeframes.");
}
//+------------------------------------------------------------------+