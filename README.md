# Make PDF package

This package produces a PDF output from TEI files including Manuscripts 
encoded following the [Beta maṣāḥǝft Guidelines](https://betamasaheft.eu/Guidelines/) 
which follows most of the layout requirements of [Aethiopica](https://doaj.org/toc/2194-4024) and the Supplements to Aethiopica.
It is mainly intended for those users who, abiding to the copyright of the data available would want to 
produce a contribution for Aethiopica starting from existing XML data, or curate 
a catalogue to be submitted as article or as a book to the Journal Aethiopica.

This is similar to the PDF print functionality
available on the Beta maṣāḥǝft website. This package will allow you to compile a PDF  with basic customizable parts. You
can then specify all its features in the script if you want to, or you can ask the maintainer of the package
to help you with that opening issues or asking in discussions in this repository.

This can eventually be modified for other TEI based projects.

This is part of the efforts to support concrete flexible and multiple user needs 
for the project  Beta maṣāḥǝft: Manuscripts of Ethiopia and 
Eritrea (Schriftkultur des christlichen Äthiopiens und Eritreas: eine multimediale Forschungsumgebung)

This package will be updated to include a schema to check several of the rules of style
but it does not yet do so.

This package is based on requirements and feedback from publication projects 
by Dorothea Reule, Denis Nosnitsin and Pietro Liuzzo and was published as an independent package 
initially for a new publication project by Mersha Alehegne. 
It has been generalized and made a bit more flexible and usable without a browser and only on a local machine 
to meet the requirements of other projects at the HLCEES. This means it
is simpler than previous projects, but tries to deal with more options and 
allow more settings, so that people can have a start playing around and figuring out 
their requirements.

## Setup
You need [OxygenXML Editor](http://www.oxygenxml.com/) to run this package. The package relies
on the XQuery enging and FOP processor delivered with Oxygen and is set up to do that.
If asked to allow modifications to Oxygen preferences, please, say yes.

Once you have downloaded, or forked and cloned this repository, open from `catalogue.xpr`. If you are working in a team, you can each have this locally and try out sharing settings.

This will open as a project in Oxygen and present you a Project view, by default on the left.

Your main file here is `driver.xml`. In here you write your article using TEI elements
or your book, and include manuscripts for your catalogue, 
and add or include all its parts.

You have two setting files. 
1. One is the Apache FOP configuration file. This is needed by the package, but you should not need to edit it unless you actually know that you need to
2. Your `settings.xml`file allows you to decide on some parts of the output. For example if it is going to be a book or an article, if to include indexes or not, where to put the bibliography, etc.

There are then three directories, 
 - one for the manuscripts TEI files (`mss`), 
 - one for images (`images`), and 
 - one for other files (`other`), e.g. institutions if they are defined locally, or locally defined authority files.
 
Note that the img folder contains instead the image used in this documentation page, and is not used by the script.
Once you open the project, allow it to set up your software and make sure you can 
use xi:include in the preferences. This should be set by the project itself for you.
![img/XInclude.png](img/XInclude.png)

You will need to create a directory called fonts and store in it the fonts listed in `fopconfig.xml`.

## Make the PDF
To make the PDF, click the small red play button at the top in your Oxygen editor. 

This is already setup to run the `PDF.xql` script, 
which will take into consideration your settings, as defined in `settings.xql`. Some more details about
this process and how you can adapt it follow. Anything can be adapted and is likely
to need adaptation to meet your encoding choices and desired output in the limits of
authorial decisions.
The produced PDF will open in your preferred system application for that.

There are two files loaded into the script directly, the list of editors and that of DomLib manuscripts. These can be changed to local lists or removed if not needed.

### Additional transformation
You may wish to edit manually your XSL-FO in cases where you did not manage to fix the XQuery for your needs. It is recommended that you limit these changes to a very minumum and that you keep them for the very very end.
To store the .fo file open driver.xml and click on "Configure Transformation Scenario". Select `catalogue2FO` instead of catalogue2PDF. This will save and open a file called catalogue.fo, overwriting previous versions of it. 
Once you are finished with the final touches, you can transform this into PDF by running from this file the preconfigured transformation FO2PDF.
Be carefull after modifying this catalogue.fo file. If you run again from `driver.xml` the catalogue2PDF transformation scenario your PDF will be overwritten, not your FO, which will be simply ignored. If you run again from `driver.xml` the catalogue2FO transformation scenario your FO will be overwritten, with no effect on your PDF until you also run FO2PDF. Changing filenames in the output section of the transformation scenario, or moving your output file once transformed,  will allow you to preserve previous version of each file. 

If you want to check your FO for debugging purposes, you can run from `driver.xml`  both catalogue2FO and catalogue2PDF selecting them both in "Configure Transformation Scenario" .


## driver.xml
This package was designed for catalogues, although it can be 
used for other purposes as well, by simply not including the manuscripts.
This source file uses `<teiCorpus>` to group under 
one `<teiHeader>` the selection of manuscripts. You can 
thus add all the information regarding this group of manuscripts, 
regardless of your selection. You may store your manuscripts as a local 
copy in mss or point to another directory in the xi:nclude elements. 
Thus you can also include a local path 
to a GitHub repository, if you want to maintain a single flow for your data. Mixing is also fine, but tidiness always helps.
This is an example of including a file with a relative path to the provided manuscripts directory.
```xml
<xi:include 
        xmlns:xi="http://www.w3.org/2001/XInclude" 
        href="mss/simple.xml">
      <xi:fallback>
         <p>Psalter</p>
      </xi:fallback>
   </xi:include>
```
If you have on the desktop your a folder with cloned repositories from GitHub, switched at any branch,
you can point to that.

```xml
<xi:include 
        xmlns:xi="http://www.w3.org/2001/XInclude" 
        href="/path/to/my/github/manuscripts/repository/mss1.xml">
      <xi:fallback>
         <p>fallback name of the manuscript</p>
      </xi:fallback>
   </xi:include>
```

Having a fallback will help you in case you have many files and one cannot be found to find quickly which one is missing.

By default manuscripts are printed and ordered regardless of their position of inclusion in `driver.xml`, looking instead at their shelfmark.

Note that the print process supports lightly as well as more deeply encoded manuscripts. The example has three paragraphs of information as text, no further encoding.
The package was developed to support manuscripts deeply encoded as, e.g. those 
of the (Dayr as-Suryān Collection)[https://betamasaheft.eu/DSintro.html].

### General behaviours

The Package uses
- the [EthioStudies Library](https://www.zotero.org/groups/358366/ethiostudies/items) and the [HLZ CSL Style](https://betamasaheft.github.io/bibliography/) to print citations and bibliography. These defaults can be changed in `settings.xml`.
- the [Beta maṣāḥǝft API](https://betamasaheft.eu/apidoc.html) to print standard names of persons, places and manuscripts, as well as the standard title of literary works including their Clavis Aethiopica number (CAe)
- the DTS protocol to fetch information from other authoritative sources providing this API.

If these resources happen to be unavailable or you have 
no internet connection to let Oxygen access them, this will not work.
This also means that there is a certain amount of dependency on 
the Beta maṣāḥǝft research environment and Zotero API.


Validation with a specific style schema is on the way and will be included in driver.xml, so that it does not affect the included TEI files and their schema association.

Indexes rely on the presence of encode `persName`, `placeName` and `term` elements. If these are not present, no index will be printed.
These will use only the latest available version in the research environment, not the eventually available newer version in one of your local branches for
[persons](https://github.com/BetaMasaheft/Persons) or [places](https://github.com/BetaMasaheft/Places) repositories.

#### TEI elements used in driver.xml

In driver.xml you can write any parts of your proposed contribution which are not 
encoded as manuscripts. Introduction, other chapters, appendixes, etc.

Links
```xml
<ref target="http://www.thelevantinefoundation.co.uk">the levantine</ref>
```                    
 ref with type figure, internal, manuscript, work with 
respectively the ids of a figure in a figure element, a chapter 
or any other node with a xml:id, a manuscript in BM a work in BM
 
bibliographical citations
 ```xml
 <bibl>
 <ptr target="bm:Meinardus1961Monks"/>
 <citedRange unit="page">117</citedRange>
 </bibl>
```

persons and places
```xml
<placeName ref="LOC6126WadinN"></placeName>

<persName ref="PRS7185Mosesof"></persName>
```
currently wikidata pointers and other external pointers are  not supported.

footnotes
```xml
<note>to make a footnote</note>
```

For lists, quotes and tables, standard TEI can be used. These are formatted according to Aethiopica Supplements requirements (2018).

#### TEI elements used in Manuscripts (mss/)

Please see 
[‘Beta maṣāḥǝft Guidelines on encoding Manuscripts](https://betamasaheft.eu/Guidelines/?id=manuscripts)

Everything which is documented there is ok, but may not be printed out. 
Please ask if something is missing, either opening an issue or using the discussion feature.
You can work with this also if your encoding is not very detailed (see example files).


#### Bibliography

The bibliography is compiled from the Zotero EthioStudies Group using both for citations and references the HLZ styles.
This does not guarantee the correctness of it, please see the relative documentation linked above.

#### Identifies entities (persons, places, works)
If you use `persName` and `placeName`, these will be made into links and if they do not contain text, they will print out the 
current standard name from BM. In the case of Works this follows some more complex requirements, which can be adjusted for specific use cases
and include the Clavis Aethiopica number.

### Figures

You may have your local files or not yet published images.
These can be put into the images folder and refer to by their filename.

```xml
<figure>
      <graphic url="images/myImage.jpeg" >
              <desc>Caption of my image</desc>
       </graphic>
</figure>
```
In the url attribute you may also point to an image available via any IIIF server, using its URL. Make sure you have permission to do so if that is required by the provider of the images.
```xml
<figure>
      <graphic url="https://betamasaheft.eu/iiif/AP/046/AP-046_014.tif/665,1084,465,125/full/0/default.jpg" >
              <desc>Caption of my image</desc>
       </graphic>
</figure>
```


You can also organize images in columns, for example
adding the images into a table

```xml
<table>
      <row role="label">
            <cell></cell>
            <cell></cell>
       </row>
       <row>
          <cell>
            <figure>
           <graphic url="images/imageleft.jpeg" >
              <desc>Caption of my image to the left</desc>
           </graphic>
           </figure>
         </cell>
            <cell>
            <figure>
               <graphic url="images/imegeright.jpeg">
                  <desc>Caption of my image to the right</desc>
               </graphic>
            </figure>
            </cell>
         </row>
         </table>
```

## Settings
In the file `settings.xml` you can decide on some of the features of your output. More customization options can be added upon request and the file itself contains these instructions.
The `settings.xml`file has already some configuration, if you want to get back to all defaults, edit or copy over from `settingstempalte.xml`.

` <format>book</format>`

This value can be set to "book", for the layout of a supplement 
        for Aethiopica or to "article" for a contribution to the 
        journal Aethiopica. In the second case, 
        items in orderOfParts like title page, acknowledgments, 
        toc, indexes should be omitted.
  
If your manuscripts all use a specific prefix for identification, please state it in the following element
 `  <localPrefix>Addis Ababa </localPrefix>`

In `<orderOfParts>` you can set the order and existence of parts of your catalogue
        simply move the tags and add the value 'yes' or 'no'.
        more parts can be added, but will require modifications to the package. If a manuscript does not contain a given part this will not be used.

  If you are printing a catalogue, into `<catalogueEntries>` you can decide in which order to
    treat the different parts of your entry, and which to include or not.
  Commonly you will list the contents of each manuscript. If you have selected this in   `<catalogueEntries>`
  you can further define what will be printed out in `<contentsStructure>`.
  
Exceptions are the rule and there are several you can set for contents, additions, keywords.
If you set indexes to be part of your publication, in `<indexes>` you can decide which indexes to print
    there can be more, and they can be better specified for selection and rendering, 
    
## Changing layout and style requirement for a publisher other than *Aethiopica*

If you want to use the data and the package, but need to work with a different editor with different requirements, please check first that they will be happy with a PDF delivery. 
If they are, you will need to change several things in the `PDF.xql` script. Please make a fork before you do this.
While changes in the order of the parts  of the data or the bibliography style may probably be easily done through `settings.xml` layout requirements will have to be set in
- the fopconfig.xml
- the PDF.xql
- local fonts repository

in the Xquery you will find `fo:` elements, which are wonderfully documented for example at https://www.antennahouse.com/xsl-fo-overview or https://www.data2type.de/xml-xslt-xslfo/xsl-fo. 
In `PDF.xql` you will find layout master, static simple pages masters, which you can modify to your needs. To check the consistency of your XSL-FO output you can generate the XSL-FO first, Oxygen will validate it.

## Managing your project
The Beta maṣāḥǝft Guidelines contain additional, higher level, and finer grained information related to this. See for example
- [A Digital-first Collaborative Catalogue of Manuscripts](https://betamasaheft.eu/Guidelines/?q=PDF&id=catalogueworkflow)
- [A Digital-first Collaborative Critical Edition](https://betamasaheft.eu/Guidelines/?q=PDF&id=editionworkflow)
- [This documentation as a presentation](https://docs.google.com/presentation/d/e/2PACX-1vSe763ALF1tB4B3Jwuf9YVwoN1aB67Cu6eZJJTGq7WU06ikWdQzRSTbm_ScZIwKcPrTEVGOCl2icHI-/pub?start=false&loop=false&delayms=3000&slide=id.gde2f7d93e5_0_0)