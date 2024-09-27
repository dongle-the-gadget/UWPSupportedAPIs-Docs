namespace UWPSupportedAPIsWeb.Models;

public class SearchViewModel
{
    public static readonly SearchViewModel Empty = new();

    public string Query { get; init; } = string.Empty;

    public int Max { get; init; } = 0;

    public int Skipped { get; init; } = 0;

    public IEnumerable<Method> Methods { get; init; } = Array.Empty<Method>();
}

public class Method
{
    public required string Name { get; set; }

    public required string MinVersion { get; set; }
}