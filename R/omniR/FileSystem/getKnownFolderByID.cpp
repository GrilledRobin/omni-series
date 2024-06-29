/*
// Quote: https://stackoverflow.com/questions/33394934/converting-std-cxx11string-to-stdstring
#define _GLIBCXX_USE_CXX11_ABI 0
// Quote: https://teuder.github.io/rcpp4everyone_en/050_c++11.html
// [[Rcpp::plugins("cpp11")]]
*/
#include <windows.h>
#include <libloaderapi.h>
#include <rpcdce.h>
// Quote: https://stackoverflow.org.cn/questions/12871513#google_vignette
#define _WIN32_WINNT 0x0600
#include <shlobj.h>
#include <combaseapi.h>
#include <wchar.h>
#include <Rcpp.h>
/*
#define _WIN32_WINNT 0x0502
// Quote: https://stackoverflow.com/questions/21378484/pragma-commentlib-v-import
// Below statement causes Rcpp::sourceCpp() to crash, which leads the R session to crash as well
#import "C:\\Windows\\System32\\ole32.dll"

// #pragma ... is ignored in .cpp script
// Quote: https://blog.csdn.net/qq_35624156/article/details/79864947
#pragma comment(lib,"winmm.lib")
// Quote: https://stackoverflow.com/questions/27613278/trying-to-add-user32-lib-to-linker-instead-of-using-pragma-comment-lib-user3
#pragma comment(linker,"ole32.dll")

----Includes
<libloaderapi.h>
	|<GetProcAddress>
<combaseapi.h>
	|<LoadLibrary>
	|<FreeLibrary>
	|<CLSIDFromString>
	|<CoTaskMemFree>
<shlobj.h>
	|<SHGetKnownFolderPath>
	|<KF_FLAG_DEFAULT>

----Quotes
https://stackoverflow.com/questions/35042967/cannot-get-shgetknownfolderpath-function-working
https://cpp.hotexamples.com/examples/-/-/SHGetKnownFolderPath/cpp-shgetknownfolderpath-function-examples.html
https://www.devhut.net/vba-getting-the-path-of-system-folders/
https://stackoverflow.com/questions/58278648/error-shgetknownfolderpath-was-not-declared-in-this-scope
https://stackoverflow.com/questions/42841832/how-to-use-cstring-object-in-shgetknownfolderpath-api-to-get-programdata-path
https://stackoverflow.com/questions/4339960/how-do-i-convert-wchar-t-to-stdstring
https://stackoverflow.com/questions/68687851/pragma-directive-to-get-thread-number-not-working-rcpp
https://stackoverflow.com/questions/8696653/dynamically-load-a-function-from-a-dll

<CLSIDFromString>
https://learn.microsoft.com/zh-cn/windows/win32/api/combaseapi/nf-combaseapi-clsidfromstring
<CoTaskMemFree>
https://learn.microsoft.com/zh-cn/windows/win32/api/combaseapi/nf-combaseapi-cotaskmemfree
*/

typedef HRESULT (__stdcall *ptr_CLSIDFromString)(LPCOLESTR, LPCLSID);
typedef HRESULT (__stdcall *ptr_CoTaskMemFree)(LPVOID);

// [[Rcpp::export]]
SEXP getKnownFolderByID(std::wstring fid, DWORD dwFlag = 0x00000000){
	// 100. Load the functions from the DLL at runtime
	// [ASSUMPTION]
	// [1] Below two functions reside in the DLL which we aim to load at runtime
	// [2] The header file to include only provides the namespace instead of the definition
	HINSTANCE hGetProcIDDLL = LoadLibrary("ole32.dll");
	if (!hGetProcIDDLL) {
		std::cout << "could not load the dynamic library <ole32.dll>" << std::endl;
		return Rcpp::wrap("");
	}

	// 150. Resolve function address for conversion from <wstring> to <GUID>
	ptr_CLSIDFromString CLSIDFromString = (ptr_CLSIDFromString)GetProcAddress(hGetProcIDDLL, "CLSIDFromString");
	if (!CLSIDFromString) {
		std::cout << "could not locate the function <CLSIDFromString>" << std::endl;
		return Rcpp::wrap("");
	}

	// 170. Resolve function address for purging memory usage
	ptr_CoTaskMemFree CoTaskMemFree = (ptr_CoTaskMemFree)GetProcAddress(hGetProcIDDLL, "CoTaskMemFree");
	if (!CoTaskMemFree) {
		std::cout << "could not locate the function <CoTaskMemFree>" << std::endl;
		return Rcpp::wrap("");
	}

	// 300. Convert the <wstring> to <GUID> as R can only provide <character vector> for the call
	/*
		----Quote
		https://stackoverflow.com/questions/27220/how-to-convert-stdstring-to-lpcwstr-in-c-unicode
		https://www.geeksforgeeks.org/convert-stdstring-to-lpcwstr-in-c/
		https://stackoverflow.com/questions/2824451/convert-string-to-guid-with-sscanf
	*/
	GUID pkfid;
	CLSIDFromString(fid.c_str(), &pkfid);

	// 500. Retrieve the <KnownFolderPath>
	PWSTR pszPath;
	HRESULT hr = SHGetKnownFolderPath(pkfid, dwFlag, nullptr, &pszPath);

	// 700. Convert the strings as Rcpp cannot make such conversion
	std::wstring ws_filepath(pszPath);
	std::string filepath(ws_filepath.begin(), ws_filepath.end());

	// 900. Purge memory
	FreeLibrary(hGetProcIDDLL);
	if (SUCCEEDED(hr)) {
		CoTaskMemFree(pszPath);
		return Rcpp::wrap(filepath);
	} else {
		return Rcpp::wrap("");
	}
}
