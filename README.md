# Andrioid System Information which is Open-Source, Ad-free, No Payments and Completely offline
Every new device I get I need to go through all the data especially if it's a product I review as I have seen [Manufacturer's lying about the specifications of the device](https://ni6hant.com/projectors/hy/300-pro-plus/). So, I decided to create something that can be easily downloaded from the playstore that's not full of crap(full-screen ads, payment screens, annoying naggings, privacy risks permissions access and just NOT BEING SIMPLE).

# Download & Install
You can download it directly from  [Play Store](https://play.google.com/store/apps/details?id=com.ni6hant.systeminfo) or [Releases Tab](https://github.com/ni6hant/android-system-info-open-source-ad-free/releases).

# Developer Notebook
## System Design Choices
1. Explanation Added
<br>While I was pulling all system information to show in application I realized there are a lot of technical stuff in it that even I don't understand so I decided to add an Explanation button which the AI suggested to just use an alert-box but I confronted it as it was not an actual alert and it didn't fit the use case. We ended up using something much less promiscuous.

## Bugs

1. Network Infomation doesn't show
<br>While the application works perfectly on the local version, the play store version doesn't show the network information at all. For this version, the network part has been wrapped around a try-catch block and show an error in the production version of the application because there is where the issue lies.
<br>
The issue is most likely in the missing permissions which I have already fixed but since the time to deploy can be very long, I decided to add it in this version and will be removed from the next one as required.

