
# # subject level directory
# UCT_6910_35_Khula_LEAP_Khula_191_35066412_3mo
# # unknown level per aquisition 
# 20220510_1248_Khula_191_49292365_3MO
# # aquisition label
# # 7_T2__AXI___DL_-NOT_FOR_DIAGNOSTIC_USE


wd=./data/
mkdir ${wd}/mqc # manual quality control
mkdir ${wd}/eph # ephermeral

for subj in `ls ${wd}/raw`
    do
    # Gather labels
    site="$(echo ${subj} | cut -d'_' -f1)"
    study="$(echo ${subj} | cut -d'_' -f4)"
    id="$(echo ${subj} | cut -d'_' -f3)"
    timepoint="$(echo ${subj} | cut -d'_' -f9)"

    if [ ! -z "$study" ] || [ ! -z "$id" ] && [ ! -z "$timepoint" ]; 
        then
        echo "^^"
        echo "Processing site-${site}_sub-${study}0${id}_ses-$timepoint... "
        echo "^^"
        for ses in `ls ${wd}/raw/${subj}/20*/`;
            do
            echo "ses is $ses"
            for aq in `ls ${wd}/raw/${subj}/${ses}`;
                do
                echo "aq is ${aq}"
                mkdir -p ${wd}/eph/site-${site}_sub-${study}0${id}/site-${site}_sub-${study}0${id}_ses-${timepoint}/${aq}/nifti
                tmpPath=${wd}/eph/site-${site}_sub-${study}0${id}/site-${site}_sub-${study}0${id}_ses-${timepoint}/${aq}/nifti/
                dcm2niix -z y -f %p -o ${tmpPath} ${wd}/raw/${subj}/${ses}/${aq}/ # https://github.com/rordenlab/dcm2niix/issues/276 

                echo "Copying to source dir in BIDS format..."
                for key in $(cat $config | jq '.descriptions | to_entries[] | .key'); 
                    do
                    sd=$(cat $config | jq -r '.descriptions['$key'].criteria.SeriesDescription');
                    #Match data with index file
                    if [[ $scan = $sd ]]; then
                        dt=$(cat $config | jq -r '.descriptions['$key'].dataType')
                        ml=$(cat $config | jq -r '.descriptions['$key'].modalityLabel')
                        cl=$(cat $config | jq -r '.descriptions['$key'].customLabels')

                        echo "${out}/sub-${sub}/ses-${sesh}/${dt}/${ml}/"
                        mkdir -p ${out}/sub-${sub}/ses-${sesh}/${dt}/${ml}/

                        for scanData in `ls -f ${wd}/raw/${project}/${sub}/${sesh}/scans/${scan}/resources/NIFTI/`; 
                            do
                            sdata=`basename $scanData`
                            echo "sdata is $sdata"
                            suf=$(echo $sdata | cut -d'.' -f2,3)
                            echo "suf is $scanData"
                            for im_files in `ls ${wd}/raw/${project}/${sub}/${sesh}/scans/${scan}/resources/NIFTI/*.${suf}`; 
                                do
                                cp ${im_files} ${out}/sub-${sub}/ses-${sesh}/${dt}/${ml}/sub-${sub}_ses-${sesh}_${cl}.${suf}
                                echo "output /sub-${sub}/ses-${sesh}/${dt}/${ml}/sub-${sub}_ses-${sesh}_${cl}.${suf}"        
                            done
                        done
                    fi    
                done
            done
        done
    else
        echo "^^"
        echo " njb-WARNING: subj-${study}0${id} naming convention error. Check mqc (manual QC) directory"
        echo "^^"
        cp -r ${wd}/raw/${subj} ${wd}/mqc/${subj}
    fi
done
