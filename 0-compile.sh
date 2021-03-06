#!/bin/bash
#
# Uebersetzt OpenGTA2 unter Ubuntu
#
# Irgendwas stimmt mit glfw noch nicht ganz, zum einen benoetigt es, dass man
# explizit mit libpthread und libXrandr linkt, zum anderen geht es nur, wenn
# man es statisch linkt
#
CC="g++"
LD="gcc"
COMPILE_INCLUDES="-g -fPIC -O2 -Wpointer-arith"
COMPILE_OPTIONS="-D_DEBUG"
LINK_INCLUDES="-lm -lpthread -lXrandr -lGL -lGLU"
LINK_OPTIONS=""
OUTPUT_FILE="opengta2.app"
TMP=".tmp-opengta2"



# Alle Sourcedateien in einem Ordner compilieren
#
# @param $1 Ordner in welchem sich die Sourcedateien befinden
# @param $2 Array von in diesem Ordner zu uebersetzenden Quelldateien
function compile {
	local FILES=(`echo "$2"`)

	if [ -d "${TMP}" ]; then
		cd "${TMP}"
	else
		echo "Warning: could not change into directory ${TMP} (pwd is `pwd`)"
		exit 1
	fi

	if [ -d "${1}" ]; then
		echo "Compiling sources in directory ${1}"
	else
		echo "Directory ${1} doesn't exist"
		exit 1
	fi

	CNT=0
	TOTAL=${#FILES[@]}
	for FILE in $2
	do
		# Information an Benutzer ausgeben
		let CNT=CNT+1
		echo "Compiling ${1}/${FILE} (${CNT}/$TOTAL)"

		# Handelt es sich um eine C++ Quellcodedatei?
		if [ -e "${1}/${FILE}.cpp" ]; then
			$CC $COMPILE_INCLUDES $COMPILE_OPTIONS -c "${1}/${FILE}.cpp" -o "${1}/${FILE}.o"
		else
			echo "Don't know how to compile ${1}/${FILE} (file ${1}/$FILE.{cpp} doesn't exist)"
		fi
	done

	cd "../"
}


# Linkt die uebergebenen Dateien zu einer Ausfuehrbaren Datei zusammen
#
# @param $1 Ordner in welchem die Objektdateien liegen
# @param $2 Array von zusammenzulinkenden Objekten
# @param $3 Ausgabedatei
function link {
	local FILES=(`echo "$2"`)

	if [ -d "${TMP}" ]; then
		cd "${TMP}"
	else
		echo "Directory ${TMP} doesn't exist"
		exit 1
	fi

	if [ -d "${1}" ]; then
		echo "Linking objects in ${1}"
	else
		echo "Directory ${1} doesn't exist"
		exit 1
	fi

	if [ "" == "${3}" ]; then
		echo "Missing output_file argument while calling link"
		exit 1
	fi
	
	# Objektdateien aneinanderreihen
	TO_LINK=""
	for FILE in $2
	do
		# Wenn die Datei absolut referenziert ist, dann ist eine
		# relative Referenzierung nicht mehr noetig
		if [ -e "${FILE}" ]; then
			FILE="${FILE}"
		else
			FILE="${1}/${FILE}.o"
		fi

		if [ -e "${FILE}" ]; then
			TO_LINK="${TO_LINK} \"${FILE}\""
		else
			echo "Object file ${FILE} doesn't exist"
		fi
	done

	# Objektdatei Linken (warum geht das nicht direkt ^^)
	HLP=".b99a0720-0ab2-11df-8a39-0800200c9a66"
	echo $LD $LINK_INCLUDES $LINK_OPTIONS -o $3 $TO_LINK > "${HLP}"
	chmod +x "${HLP}"
	./$HLP
	rm "${HLP}"

	cd "../"
}





# Altes temporaeres Verzeichnis loeschen
if [ -d "${TMP}" ]; then
	rm -r "${TMP}"
fi
mkdir "${TMP}"


# Zum Build benoetigte Dateien kopieren
cp -r "include" "${TMP}/include"
cp -r "opengta2" "${TMP}/opengta2"
cp -r "tools" "${TMP}/tools"


# Folgende Dateien muessen uebersetzt und gelinkt werden
OPENGTA2=(			\
	"anim"			\
	"camera"		\
	"chunkload"		\
	"clientlist"		\
	"cmain"			\
	"collision"		\
	"console"		\
	"convar"		\
	"debugtest"		\
	"draw"			\
	"font"			\
	"game"			\
	"graphics"		\
	"input"			\
	"log"			\
	"main"			\
	"malloc"		\
	"map"			\
	"map_geom_cl"		\
	"map_geom"		\
	"map_render"		\
	"matrix"		\
	"network"		\
	"ped"			\
	"ped_mgr"		\
	"ped_render"		\
	"perfhud"		\
	"screen"		\
	"smain"			\
	"texture_atlas"		\
	"thread"		\
	"timer"			\
	"utf8"			\
	"vbuffer"		\
	"vector"		\
)


# Kompletten opengta2 Ordner uebersetzen (@see http://www.faqs.org/docs/abs/HTML/assortedtips.html)
arg=`echo ${OPENGTA2[@]}`
compile "opengta2" "$arg"
link "opengta2" "$arg /usr/lib/libglfw.a" $OUTPUT_FILE

# Testweisen nur einzelne Dateien uebersetzen
#TEST_FILES=( "chunkload" )
#arg=`echo ${TEST_FILES[@]}`
#compile "opengta2" "$arg"
#link "opengta2" "$arg" "test.out"



# Compile Toolchain
TOOL_CHUNKMERGE=( "chunkmerge" )
arg=`echo ${TOOL_CHUNKMERGE[@]}`
compile "tools/chunkmerge" "$arg"
link "tools/chunkmerge" "$arg" "tools/chunkmerge.app"

TOOL_GENFONT=( "genfont" "texatlas" )
arg=`echo ${TOOL_GENFONT[@]}`
cp "tools/shared/texatlas.h" "${TMP}/tools/genfont"
cp "tools/shared/texatlas.cpp" "${TMP}/tools/genfont"
compile "tools/genfont" "$arg"
link "tools/genfont" "$arg" "tools/genfont.app"

TOOL_GMP2MAP=( "gmp2map" )
arg=`echo ${TOOL_GMP2MAP[@]}`
compile "tools/gmp2map" "$arg"
link "tools/gmp2map" "$arg" "tools/gmp2map.app"

TOOL_SDT2WAV=( "sdt2wav" )
arg=`echo ${TOOL_SDT2WAV[@]}`
compile "tools/sdt2wav" "$arg"
link "tools/sdt2wav" "$arg" "tools/sdt2wav.app"

TOOL_STY2TEX=( "sty2tex" "tilewrite" "texatlas" )
arg=`echo ${TOOL_STY2TEX[@]}`
cp "tools/shared/texatlas.h" "${TMP}/tools/sty2tex"
cp "tools/shared/texatlas.cpp" "${TMP}/tools/sty2tex"
compile "tools/sty2tex" "$arg"
link "tools/sty2tex" "$arg" "tools/sty2tex.app"

TOOL_TXT2CHUNKED=( "txt2chunked" )
arg=`echo ${TOOL_TXT2CHUNKED[@]}`
compile "tools/txt2chunked" "$arg"
link "tools/txt2chunked" "$arg" "tools/txt2chunked.app"





