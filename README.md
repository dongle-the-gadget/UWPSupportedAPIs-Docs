# UWPSupportedAPIs-Docs
A list of Win32 APIs supported* by UWP.
> [!NOTE]
> We define "supported" here as in, allowed for use by UWP apps submitted to the Microsoft Store.
> Some other APIs not listed in this repository can work within UWP apps,
> yet are not approved for use by the Microsoft Store.

## Motivation
Unfortunately, there are many misconceptions around what APIs are allowed within the "UWP sandbox" (actually a misnomer, its correct name is AppContainer). 
This problem is exacerbated by the fact that Microsoft themselves perpetuates unclear information inside their official documentation. 
This lackluster approach to communication has led to many app developers using `runFullTrust` (which is the equivalent of escaping the AppContainer sandbox) when it isn't actually needed.

We hope that, with this project, we can shed light on how permissible AppContainer actually is, and what you can actually do with UWP.

<sup>*Oh, and also to stop [Ahmed Walid](https://twitter.com/AhmedWalid605) from complaining about how bad the official documentation is.* 😉😂</sup>

### Problems with existing approaches
#### Microsoft Learn (formerly Microsoft Docs)
As said, Microsoft Learn suffers from outdated or incorrect information when it comes to UWP compatibility.
For instance, `GetModuleHandleW` is listed in Microsoft Learn as ["desktop apps only"](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulehandlew#requirements),
despite the fact that this API has been supported for UWP apps since the Windows SDK version 18362.

#### Windows App Certification Kit
The Windows App Certification Kit includes a list of supported APIs, which are actually correct (for the SDK version that they come with). 
We scrape its files to find out which Win32 APIs are supported.

However, there is a bug in the Windows App Certification Kit: 
It always downloads an outdated version of the list, no matter the SDK version, 
even though the server literally warns the kit that the list it downloads is outdated.
