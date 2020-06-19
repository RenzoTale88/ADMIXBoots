
## Create tree
To create the tree, it is necessary to have installed:

 1. FigTree[https://github.com/rambaut/figtree]
 2. forester[https://sites.google.com/site/cmzmasek/home/software/forester/phyloxml-converter], 
 3. Graphlan[https://bitbucket.org/nsegata/graphlan/wiki/Home]
 4. Python 2.7 with the packages colormap, xml and biopython.

The tree is processed using FigTree as follow:

   a. Generate a tree with the branches coloured, but in the same order and length
   b. Save it as a Nexus file (file > export tree > Nexus > flag all options)
   c. Generate a transformed tree (left menu > tree > flag transform branches)
   d. Save it as nexus tree as well
 
Then, open the two trees in forester.jar and export them as PhyloXML 
   (file > save tree as... > select PhyloXML)

The two phyloxml files are then joined using JoinPhyloXMLannotations.py:

    python JoinPhyloXMLannotations.py Tree1.xml Tree2.xml

The resulting phyloxml is then fixed for marker scale and labels size using the script FixGraphlanXml.py:

    python FixGraphlanXml.py final.xml 10 1 > toplot.xml

Finally, run graphlan as follow:

    graphlan.py toplot.xml mytree.png --dpi 300 --size 15

This will generate the resulting phylogenetic tree. 
