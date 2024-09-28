using Lucene.Net.Analysis;
using Lucene.Net.Index;
using Lucene.Net.Search;
using Lucene.Net.Search.Grouping;
using Lucene.Net.Store;
using Lucene.Net.Util;
using LuceneCommons;
using UWPSupportedAPIsWeb.Models;

namespace UWPSupportedAPIsWeb.Services;

public class SearchService : IDisposable
{
    private FSDirectory fsdir;
    private DirectoryReader reader;
    private IndexSearcher searcher;
    private Analyzer analyzer;
    private static readonly Sort docSort = new Sort(new SortField("build", SortFieldType.STRING));

    public SearchService()
    {
        fsdir = FSDirectory.Open("LuceneIndex");
        reader = DirectoryReader.Open(fsdir);
        searcher = new IndexSearcher(reader);
        analyzer = new WinAPIAnalyzer();
    }

    public SearchViewModel ReturnMethods(string query, int offset = 0)
    {
        GroupingSearch groupingSearch = new("name");
        groupingSearch.SetAllGroups(true);
        groupingSearch.SetGroupDocsLimit(1);
        groupingSearch.SetSortWithinGroup(docSort);

        QueryBuilder builder = new(analyzer);
        Query q = builder.CreatePhraseQuery("name", query);

        ITopGroups<object> returnedMethods = groupingSearch.Search(searcher, q, offset, 10);
        List<Method> methods = new List<Method>(returnedMethods.Groups.Length);
        foreach (var methodDocGroup in returnedMethods.Groups)
        {
            var doc = searcher.Doc(methodDocGroup.ScoreDocs[0].Doc);
            methods.Add(new Method
            {
                Name = doc.GetField("name").GetStringValue(),
                MinVersion = doc.GetField("build").GetStringValue()
            });
        }

        return new SearchViewModel
        {
            Query = query,
            Methods = methods,
            Max = returnedMethods.TotalGroupCount.GetValueOrDefault(),
            Skipped = offset
        };
    }

    public void Dispose()
    {
        reader.Dispose();
        fsdir.Dispose();
    }
}