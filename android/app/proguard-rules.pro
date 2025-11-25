# Keep AppAuth classes to prevent state loss
-keep class net.openid.appauth.** { *; }
-dontwarn net.openid.appauth.**

# Keep activity state for OAuth
-keepclassmembers class * extends android.app.Activity {
   public void *(android.view.View);
}
