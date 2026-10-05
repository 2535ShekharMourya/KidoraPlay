# Release builds shrink code with R8. Keep what is created by reflection.

# Room databases (WorkManager, used by the ads SDK, keeps its job queue in
# one). Room instantiates the generated *_Impl class by reflection; without
# this the app crashes at launch: "Failed to create an instance of
# androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
