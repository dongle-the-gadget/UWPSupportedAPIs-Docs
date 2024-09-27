using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using UWPSupportedAPIsWeb.Models;
using UWPSupportedAPIsWeb.Services;

namespace UWPSupportedAPIsWeb.Controllers;

[Route("")]
public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly SearchService _searchService;

    public HomeController(ILogger<HomeController> logger, SearchService searchService)
    {
        _logger = logger;
        _searchService = searchService;
    }

    [Route("")]
    public IActionResult Index()
    {
        return View();
    }

    [Route("search")]
    public IActionResult Search([FromQuery]string q, [FromQuery]int skip = 0)
    {
        if (string.IsNullOrWhiteSpace(q))
            return View(SearchViewModel.Empty);

        SearchViewModel methods = _searchService.ReturnMethods(q, skip);
        return View(methods);
    }

    [Route("/privacy")]
    public IActionResult Privacy()
    {
        return View();
    }

    [Route("/error")]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
