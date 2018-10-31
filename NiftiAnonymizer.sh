#!/bin/bash

# FullAnonymizer.sh 
# Script is used to anonymize nifti header and deface anatomical nifti images
# Written by: Ranjeet Khanuja, 2012 __Child Mind Institute__. 
# License type: Creative Commons, Attribution - non-commercial
# Defacing routine based upon defacer.py by: Russ Poldrack via Github
# Template taken is the standard fsl brain template
# The defacing module works for images which does not have neck tissue


#no of arguments
ARGS=2

#mask to be used 
face_mask=facemask_mni.nii.gz 
template=MNI152_T1_1mm_brain.nii.gz



#temperary variables defined
tempfile=tempfile
tmpmat=tmpmat
invmat=invmat
analyze=analyze
new=_new
out=_out
headfile=.hdr
imagefile=.img
gz=.nii.gz
nii=.nii
deface=_defaced
rpi=_RPI
temp=_temp
dot=.
bet=_bet
change=_chg


if [ $# -ne "$ARGS" ]
then 
 echo "Usage:  $0 NIFTI_File  Is_This_Nifti_File_Anatomical - yes/no"
 echo "Example: ./NiftiAnonymize.sh mprage.nii.gz yes"
 exit 1
fi


if [ -f "$1" ]
 then
   input_nifti_file=$1
else
   echo " File \"$1\" does not exist. "
   exit 1
fi

echo "process begins" 


xpath=$(dirname $input_nifti_file)
xpath=$xpath"/"
filename=$(basename $input_nifti_file)
 
extension=${filename#*.}
filename=${filename%%.*}


#nifti_file=$filename$change$dot$extension
nifti_file=$filename$change$gz

echo filepath is $xpath
echo filename is $filename
echo extension is $extension


#getting slope
scl_slope=$(fslval $input_nifti_file scl_slope)
scl_inter=$(fslval $input_nifti_file scl_inter)

echo "slope is $scl_slope"

echo "changing the data type to float"
fslmaths $input_nifti_file $nifti_file -odt float

###change nifti header

#change file to nifti_pair (.hdr and .img)
fslchfiletype NIFTI_PAIR $nifti_file $analyze



#get the required header information pizels, TR, dimensions and dataype
dim1=$(fslval $nifti_file dim1)
dim2=$(fslval $nifti_file dim2)
dim3=$(fslval $nifti_file dim3)
dim4=$(fslval $nifti_file dim4)
datatype=$(fslval $nifti_file datatype)
pixdim1=$(fslval $nifti_file pixdim1)
pixdim2=$(fslval $nifti_file pixdim2)
pixdim3=$(fslval $nifti_file pixdim3)
pixdim4=$(fslval $nifti_file pixdim4)
qform=$(fslval $nifti_file qform)


echo "Creating new Header"

#create new header from the nifti image 
#default origin as 0 0 0

cmd="fslcreatehd $dim1 $dim2 $dim3 $dim4 $pixdim1 $pixdim2 $pixdim3 $pixdim4 0 0 0 16 _temp"
echo ${cmd}
$cmd


new_file=$temp$gz

#change filetype of newly created nifti file into anlayze
fslchfiletype NIFTI_PAIR  $new_file $new

#copy orientation information
fslcpgeom $analyze$headfile $new$headfile

#copy new header into old header
cp $new$headfile $analyze$headfile

#new nifti file name

new_nifti_file=$xpath$filename$new$gz
temp_nifti_file=$filename$temp


if [ ${extension} = "nii.gz" ]
then
   fslchfiletype NIFTI_GZ $analyze $temp_nifti_file
   temp_nifti_file=$temp_nifti_file$gz
else
  fslchfiletype NIFTI $analyze $temp_nifti_file
  temp_nifti_file=$temp_nifti_file$nii
fi

echo "changing the data type back to short"
slope=${scl_slope/.*}
if [ $slope -gt 0 ]
then 
  echo "scaling down voxel data"
  out_temp_file=$filename$out$gz
  fslmaths $temp_nifti_file -sub $scl_inter -div $scl_slope $out_temp_file
  fslmaths $out_temp_file $new_nifti_file -odt short
  rm $out_temp_file
else
  fslmaths $temp_nifti_file $new_nifti_file -odt short
fi


# remove the temperory files created
rm $analyze$headfile
rm $analyze$imagefile
rm $new$headfile
rm $new$imagefile
rm $new_file
rm $nifti_file
rm $temp_nifti_file


echo "New Nifti Image file with changed header info --> $new_nifti_file"


function deface_nifti {

  echo "Checking for facemask and tempelate files" 
  
  if [ ! -f "$face_mask" ]
    then
     echo " File \"$face_mask\" does not exist. "
     exit 1
  fi


  if [ ! -f "$template" ]
    then
     echo " File \"$template\" does not exist. "
     exit 1
  fi
  
   
   defaced_file=${xpath}${filename}${new}${deface}$gz
   nifti_file_rpi=${xpath}${filename}${new}${rpi}$gz
   
   echo "Checking the orientation"
   
   x_orient=$(fslval $input_nifti_file qform_xorient)
   z_orient=$(fslval $input_nifti_file qform_zorient)
   y_orient=$(fslval $input_nifti_file qform_yorient)
   
   echo "Orientation values $x_orient, $y_orient, $z_orient"
   
   if [ ${x_orient} = "Anterior-to-Posterior" -a  ${z_orient} = "Left-to-Right" -a ${y_orient} = "Inferior-to-Superior" ]
	then 
             echo "reorienting nifti image to RPI orientaion"
             fslswapdim $new_nifti_file  -z -x y  $nifti_file_rpi
   elif [ ${x_orient} = "Left-to-Right" -a  ${z_orient} =  "Anterior-to-Posterior" -a ${y_orient} = "Inferior-to-Superior" ]
	then 
             echo "reorienting nifti image to RPI orientaion"
             fslswapdim $new_nifti_file  -x -z y  $nifti_file_rpi
   elif [ ${x_orient} = "Left-to-Right" -a  ${z_orient} =  "Inferior-to-Superior" -a ${y_orient} = "Posterior-to-Anterior" ]
	then 
             echo "reorienting nifti image to RPI orientaion"
	     fslswapdim $new_nifti_file  -x y z  $nifti_file_rpi
   elif [ ${x_orient} = "Right-to-Left" -a  ${z_orient} =  "Anterior-to-Posterior" -a ${y_orient} = "Inferior-to-Superior" ]
	then 
             echo "reorienting nifti image to RPI orientaion"
	     fslswapdim $new_nifti_file  x -z y $nifti_file_rpi
   elif [ ${x_orient} = "Right-to-Left" -a  ${z_orient} =  "Posterior-to-Anterior" -a ${y_orient} = "Inferior-to-Superior" ]
	then 
             echo "reorienting nifti image to RPI orientaion"
	     fslswapdim $new_nifti_file  x z y $nifti_file_rpi
   elif [ ${x_orient} = "Anterior-to-Posterior" -a  ${z_orient} =  "Right-to-Left" -a ${y_orient} = "Superior-to-Inferior" ]
	then 
             echo "reorienting nifti image to RPI orientaion"
	     fslswapdim $new_nifti_file  z -x -y $nifti_file_rpi
   else 
             echo "Image is already is RPI orientation"
             cp $new_nifti_file  $nifti_file_rpi
   
   fi 
   
   #checking if fslswapdim changed the oreitnation correctly or not
   x_orient=$(fslval $nifti_file_rpi qform_xorient)
   if [ ${x_orient} = "Left-to-Right" ]
    then
	      echo "changing the orientation in the header"
          fslorient -swaporient $nifti_file_rpi
   fi
   
   
   #echo "File with RPI orientation --> $nifti_file_rpi"

   echo "Defacing Begins..."
   
   tmpfile=${tempfile}$gz
   nifti_file_rpi_bet=${filename}${rpi}${bet}$gz
   
   echo "run bet"
   #remove skull and put the output in a temperary file
   bet $nifti_file_rpi $nifti_file_rpi_bet 
   
   echo "run flirt 1"
   flirt -in $nifti_file_rpi_bet -ref $template -omat $tmpmat 

   echo "get transformation matrix, invmat"
   convert_xfm -inverse -omat $invmat $tmpmat
	  
   echo "run flirt 2"
   flirt -in $face_mask -out $tmpfile -ref $nifti_file_rpi -applyxfm -init $invmat


   echo "run fslmaths"
   fslmaths $nifti_file_rpi -mul $tmpfile $defaced_file

   #remove temperary files
   echo "remove temperary files"
   rm $nifti_file_rpi_bet
   rm $tmpmat
   rm $invmat
   rm $tmpfile
   rm $nifti_file_rpi   
   return 0
}

if [ "$2" == "yes" ]
 then
   echo "Anatomical Nifti Image"
   echo "Make sure you have \"$face_mask\" and \"$template\" present in the current directory"
   "deface_nifti" 
   echo "The defaced nifti file is --> $defaced_file"
   echo "Defacing Finishes..."
else
  echo "No defacing for this file"
fi

echo "process complete"














