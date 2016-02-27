" Vim ploticus syntax file.
" Language:     ploticus
" Maintainer:   Karel Miklav <karel@lovetemple.net>
" Last change:  2013-04-18

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case match

syn cluster plAlwaysContains add=txtTodo,txtError

syn cluster plContains add=txtNumber,txtOperator,txtLink

syn match plOperator "+-*/"

syn match plNumber "\d"
syn match plDirective "#[a-z]\{2,15\}.*"
syn match plVariable "@\{1,2\}[a-zA-Z0-9_-]\+"

syn region plComment start="\/\/" end="$" contains=plTodo oneline

syn keyword plConstant 10year 12hour 2year 3hour 3month 5year 6hour Nminute
syn keyword plConstant Nsecond black blue brightblue brightgreen claret
syn keyword plConstant coral darkblue datematic day drabgreen dullyellow
syn keyword plConstant exact gray green hour inc kelleygreen lavender
syn keyword plConstant lightorange lightpurple limegreen magenta max min
syn keyword plConstant minmax minute monday month no null oceanblue orange
syn keyword plConstant pink powderblue powderblue2 purple quarter red
syn keyword plConstant redorange second skyblue sunday tan1 tan2 teal transparent year
syn keyword plConstant yellow yellow2 yellowgreen yelloworange yes

syn keyword plFunction gray grey rgb

syn keyword plKeyword abbrev abelit accum accumfield action adjust align
syn keyword plKeyword allowinlinecodes altsym altsymbol altwhen amount
syn keyword plKeyword anchor annotate area areacolor areadef areafld
syn keyword plKeyword areaname areascale arrow arrowdetails arrowhead
syn keyword plKeyword arrowheadcolor arrowheadlength arrowheadsize
syn keyword plKeyword arrowheadwidth arrowtail ascii atan atexit atof atoi
syn keyword plKeyword atol auto autodays autoheight automonths autoround
syn keyword plKeyword autosmall autowidth autoyears autozero axes axis
syn keyword plKeyword axisline axislinerange backadjust backbox backcolor
syn keyword plKeyword backdim backgroundcolor barbdir barblimits bars
syn keyword plKeyword barsrange barwidth barwidthfield basis bbdebug bevel
syn keyword plKeyword bevelrect bevelsize binmod binsize bkcolor bold both
syn keyword plKeyword bottomleft bottomlocation boundingbox boxmargin
syn keyword plKeyword boxplot breakaxis breakpoint breakreset breaks bwps
syn keyword plKeyword calcrange catbinsadjust categories catfield catlines
syn keyword plKeyword catslide cblock ceil center centered centext
syn keyword plKeyword changeunits char chdir checkuniq chunksep clickmap
syn keyword plKeyword clickmapadjust clickmapdefault clickmapextent
syn keyword plKeyword clickmaplabel clickmaplabeltext clickmapurl
syn keyword plKeyword clickmapvalformat clip clockdir closepath cluster
syn keyword plKeyword clusterdiff clusterfact clustermethod clustersep
syn keyword plKeyword clustevery cmyk color colorfield colorfld colorlist
syn keyword plKeyword colors colortext combomode comma command commandmr
syn keyword plKeyword commands commentchar complen compmethod constantlen
syn keyword plKeyword constantloc count cpulimit crop croprel crossover
syn keyword plKeyword csmap csmapdemo currentfont curvefit curveshift
syn keyword plKeyword curvetype darken data datafield datafields dataitem
syn keyword plKeyword date dateformat datesettings datetime defaultinc
syn keyword plKeyword defineunits delim density details diag diagfile
syn keyword plKeyword dirfield dirrange dirunits dobackground dopagebox
syn keyword plKeyword dots dotsize downtri dpsymbol drawcommands drawdump
syn keyword plKeyword drawdumpa dtsep dullyellow dump dumpfile dupsleg
syn keyword plKeyword echo egsf ellipse encodenames encoding endproc
syn keyword plKeyword environ errbardetails errbarfield errbarfields
syn keyword plKeyword errbarmult errfield errfile errmsgpre error
syn keyword plKeyword errormode euro evalvars exactcolorfield exists
syn keyword plKeyword explode extent fchmod fclose fflush fgets field
syn keyword plKeyword fieldname fieldnameheader fieldnamerows fieldnames
syn keyword plKeyword file fileno fill fillbleed fillcolor filter first
syn keyword plKeyword firstpoint firstslice firststub floor fmod font
syn keyword plKeyword fopen format fprintf fputc fputs frame free
syn keyword plKeyword fromcommand fromfile fseek ftell fwrite gapmissing
syn keyword plKeyword gapsize generic gesf getc getclick getdata getegid
syn keyword plKeyword getenv geteuid getpid gfff globqs grid gridblocks
syn keyword plKeyword gridlineextent gridskip groupmode gzclose gzdopen
syn keyword plKeyword gzopen gzprintf height hibevelcolor hideund
syn keyword plKeyword hidezerobars hifield hifix high hilo horizontalbars
syn keyword plKeyword hour icolor image imgfile imgheight imgwidth import
syn keyword plKeyword inches incmult inlike inra inrange instancemode
syn keyword plKeyword italic join jpeg keepall keepfields label labelback
syn keyword plKeyword labelbackoutline labeldetails labeldistance
syn keyword plKeyword labelfarout labelfield labelfmtstring labelinfo
syn keyword plKeyword labelinfotext labelmaxlen labelmode labelmustfit
syn keyword plKeyword labelonly labelpos labelrot labels labelselect
syn keyword plKeyword labelurl labelword labelzerovalue lablinedetails
syn keyword plKeyword landscape last lastseglen laststub lastx lavender
syn keyword plKeyword leftjoin leftselect leftticfield lefttri legend
syn keyword plKeyword legendentry legendlabel legendsampletype legendtype
syn keyword plKeyword lenfield lenscale lenunits line linear linebottom
syn keyword plKeyword linedetails linedir linelen linelength lineplot
syn keyword plKeyword linerange lineside linetype linewidth linkparms list
syn keyword plKeyword listsep listsize load localtime location locfield
syn keyword plKeyword lofield log10 longwayslabel lowbevelcolor lowfix
syn keyword plKeyword magfield malloc mapdemo mapfile margin mark
syn keyword plKeyword maxdrawpoints maxfields maxinit maxinpoints maxonly
syn keyword plKeyword maxproclines maxrows maxvector mean meansym median
syn keyword plKeyword mediansym memcpy memset middle midticfield mininit
syn keyword plKeyword minlabel minmaxonly minonly minorticinc minorticlen
syn keyword plKeyword minortics minute missingdatacode monday month
syn keyword plKeyword movingavg mustparen mwqy nearest newickfile nextstub
syn keyword plKeyword nfields niceci nlinesym nlocation noclear noclose
syn keyword plKeyword nodevice nolimit none nosh noshell notation
syn keyword plKeyword notexists null numbernotation numberrows numbers
syn keyword plKeyword numbersformat numberspacerthreshold numfmt numformat
syn keyword plKeyword omit omitws option order orientation original
syn keyword plKeyword originaldata outfile outfilename outlabel outline
syn keyword plKeyword outlinecolors outlinedetails outmode outr page
syn keyword plKeyword pagesize path pathname pclose pctformat percent
syn keyword plKeyword percents ping pixcircle pixdiamond pixdowntriangle
syn keyword plKeyword pixsize pixsquare pixtriangle plotwidth points
syn keyword plKeyword pointsymbol popen portrait post posteroffset print
syn keyword plKeyword printn processdata processrows projectroot
syn keyword plKeyword ptlabeldetails ptlabelfield ptlabelrange putchar
syn keyword plKeyword putenv qsort quarter raccum radius rangebar
syn keyword plKeyword rangesepchar rangesweep rect rectangle redorange
syn keyword plKeyword rejectfields reset resolution resultfieldnames
syn keyword plKeyword resultformat reverse reverseorder rewritenum
syn keyword plKeyword rightjoin rightjust rightselect rightticfield
syn keyword plKeyword righttri root rootsym rotate roundrobin sampletype
syn keyword plKeyword savetable scale scatterplot scriptdir second seglen
syn keyword plKeyword segment segmentfield segmentfields select selectrows
syn keyword plKeyword selflocatingstubs separation setfont setgid
syn keyword plKeyword setlocale setrlimit settings setuid shadowcolor
syn keyword plKeyword shadowsize shellmetachars shieldquotedvars showbad
syn keyword plKeyword showdata showpage showrange showrangelowonly
syn keyword plKeyword showresults showvalues showwithquotes shsql
syn keyword plKeyword signreverse sizefield sizescale skip slant sleep
syn keyword plKeyword slideamount small solidfill sort space specifyorder
syn keyword plKeyword sprintf sqlmode sqlmr sqrt squaredoff srand sscanf
syn keyword plKeyword stack stackfield stairoverbars stairstep standard
syn keyword plKeyword standardinput standardp start statfields stats
syn keyword plKeyword statsonly stderr stdin stdout strcasecmp strcat
syn keyword plKeyword strchr strcmp strcoll strcpy strlen strncasecmp
syn keyword plKeyword strncmp strncpy stubcull stubdetails stubevery
syn keyword plKeyword stubexp stubformat stubhide stublen stubmininc
syn keyword plKeyword stubmult stubomit stubrange stubreverse stubround
syn keyword plKeyword stubs stubslide stubsubnew stubsubpat stubvert style
syn keyword plKeyword subcatfield subcats summary sunday suppressdll
syn keyword plKeyword svgparms svgz swatchsize sweeprange sym6a symbol
syn keyword plKeyword symfield symrangefield system tabulate tagfield
syn keyword plKeyword taildetails taillen tailmode tails text text
syn keyword plKeyword textdetails textsaved textsize textwidth thinbarline
syn keyword plKeyword ticincrement ticlen tics ticsize ticslide tightcrop
syn keyword plKeyword time title titledetails tmpdir today topcenter
syn keyword plKeyword topleft total trailer transform tree truncate type
syn keyword plKeyword units unlink usecategories usedata useinc usleep
syn keyword plKeyword valfield varsym vector vennden venndisk verticaltext
syn keyword plKeyword verttext viewer wbmp white whitespace width winloc
syn keyword plKeyword wraplen xautorange xaxis xfield xfld xlocation
syn keyword plKeyword xmldecl xrange xrgb xscaletype xsort xstart
syn keyword plKeyword yautorange yaxis year years yfield yloc ylocation
syn keyword plKeyword yrange yscaletype zeroat zlevel

syn keyword plSysVar AREABOTTOM AREALEFT AREARIGHT AREATOP BREAKFIELD1 CM_UNITS
syn keyword plSysVar DATAXMAX DATAXMIN DATAYMAX DATAYMIN DEVICE NFIELDS
syn keyword plSysVar NRECORDS NVALUES PLVERSION RANGEBARMAX RANGEBARMEDIAN
syn keyword plSysVar RANGEBARMIN TOTALS XFINAL XINC XMAX XMIN XSTART YFINAL
syn keyword plSysVar YINC YMAX YMIN YSTART

syn keyword plTodo todo fixme xxx note
syn keyword plError error bug
syn keyword plDebug debug

syn case match

" Define the default highlighting.
if version < 508
  command -nargs=+ HiLink hi link <args>
else
  command -nargs=+ HiLink hi def link <args>
endif

HiLink plNumber              Number
HiLink plDirective           PreProc
HiLink plVariable            Identifier
HiLink plSysVar              Identifier
HiLink plConstant            Todo
HiLink plOperator            Operator
HiLink plFunction            Function
HiLink plComment             Comment
HiLink plDelims              Delimiter
HiLink plError               Error
HiLink plTodo                Todo
HiLink plDebug               Debug
HiLink plKeyword             Keyword
HiLink plPreProc             PreProc

delcommand HiLink

let b:current_syntax = "ploticus"

" vim: ts=2:sw=2:ft=vim
