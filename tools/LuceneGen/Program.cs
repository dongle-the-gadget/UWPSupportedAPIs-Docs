// See https://aka.ms/new-console-template for more information
using ConsoleAppFramework;
using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Standard;
using Lucene.Net.Documents;
using Lucene.Net.Index;
using Lucene.Net.Util;
using TurboXml;

using LuceneDirectory = Lucene.Net.Store.Directory;
using OpenMode = Lucene.Net.Index.OpenMode;

unsafe
{
    ConsoleApp.Run(args, &Run);
}

static void Run(string folder, string output)
{
    const LuceneVersion version = LuceneVersion.LUCENE_48;

    using LuceneDirectory indexDir = Lucene.Net.Store.FSDirectory.Open(output);
    Analyzer analyzer = new StandardAnalyzer(version);
    IndexWriterConfig indexConfig = new IndexWriterConfig(version, analyzer);
    indexConfig.OpenMode = OpenMode.CREATE;
    IndexWriter writer = new IndexWriter(indexDir, indexConfig);

    XmlHandler handler = new XmlHandler(writer);

    foreach (DirectoryInfo buildFolder in new DirectoryInfo(folder).GetDirectories())
    {
        string build = buildFolder.Name;
        handler.ChangeBuild(build);

        foreach (FileInfo file in buildFolder.GetFiles("*.xml"))
        {
            ReadOnlySpan<char> fileName = file.Name;
            int firstSeparator = fileName.IndexOf('-');
            int secondSeparator = fileName.IndexOf('.');
            string arch = fileName.Slice(firstSeparator + 1, secondSeparator - firstSeparator - 1).ToString();
            handler.ChangeArch(arch);
            using FileStream stream = file.OpenRead();
            XmlParser.Parse(stream, ref handler);
        }
    }

    writer.Commit();
}

public struct XmlHandler : IXmlReadHandler
{
    private readonly IndexWriter _indexWriter;
    private Document? _document;
    private string? _build;
    private string? _arch;

    public XmlHandler(IndexWriter indexWriter)
    {
        _indexWriter = indexWriter;
    }

    public void ChangeBuild(string build)
    {
        _build = build;
    }

    public void ChangeArch(string arch)
    {
        _arch = arch;
    }

    public void OnBeginTag(ReadOnlySpan<char> name, int line, int column)
    {
        if (name.SequenceEqual("API"))
        {
            _document = new Document();
            _document.Add(new StringField("build", _build, Field.Store.YES));
            _document.Add(new StringField("arch", _arch, Field.Store.YES));
        }
    }

    public void OnEndTagEmpty()
    {
        if (_document is not null)
            _indexWriter.AddDocument(_document);

        _document = null;
    }

    public void OnEndTag(ReadOnlySpan<char> name, int line, int column)
    {
        if (_document is not null)
            _indexWriter.AddDocument(_document);

        _document = null;
    }

    public void OnAttribute(ReadOnlySpan<char> name, ReadOnlySpan<char> value, int nameLine, int nameColumn, int valueLine, int valueColumn)
    {
        if (_document is null)
            return;

        switch (name)
        {
            case "Name":
                _document.Add(new TextField("name", value.ToString(), Field.Store.YES));
                break;

            case "ModuleName":
                _document.Add(new StringField("module", value.ToString(), Field.Store.YES));
                break;
        }
    }
}