# SPDX-License-Identifier: GPL-3.0-or-later
"""Small scientific fixtures: affine precedence and GIfTI preflight order."""
import tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import nibabel as nib
import numpy as np
from brainnet_viewer.io import read_surface,read_surface_map,read_volume

class ReaderInvariantTests(unittest.TestCase):
    def test_valid_external_gifti_array_remains_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'external.gii'
            points=np.asarray([[0,0,0],[1,0,0],[0,1,0]],dtype='<f4')
            (path.parent/'points.bin').write_bytes(points.tobytes())
            path.write_text('''<GIFTI Version="1.0" NumberOfDataArrays="2">
<DataArray Intent="NIFTI_INTENT_POINTSET" DataType="NIFTI_TYPE_FLOAT32" ArrayIndexingOrder="RowMajorOrder" Dimensionality="2" Dim0="3" Dim1="3" Encoding="ExternalFileBinary" Endian="LittleEndian" ExternalFileName="points.bin" ExternalFileOffset="0"><Data/></DataArray>
<DataArray Intent="NIFTI_INTENT_TRIANGLE" DataType="NIFTI_TYPE_INT32" ArrayIndexingOrder="RowMajorOrder" Dimensionality="2" Dim0="1" Dim1="3" Encoding="ASCII" Endian="LittleEndian" ExternalFileName="" ExternalFileOffset="0"><Data>0 1 2</Data></DataArray></GIFTI>''')
            loaded=read_surface(path)
            np.testing.assert_array_equal(loaded.points,points)
            np.testing.assert_array_equal(loaded.faces,[[0,1,2]])
    def test_entity_rejected_before_nibabel_for_both_gifti_entrypoints(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'entity.gii'
            path.write_text('<!DOCTYPE GIFTI [<!ENTITY x "forbidden">]><GIFTI Version="1.0" NumberOfDataArrays="0">&x;</GIFTI>')
            for reader in (lambda:read_surface(path),lambda:read_surface_map(path,1)):
                with patch.object(nib,'load') as parser:
                    with self.assertRaises(ValueError):reader()
                    parser.assert_not_called()

    def test_sform_qform_pixdim_and_gzip_left_flip(self):
        with tempfile.TemporaryDirectory() as directory:
            data=np.arange(24,dtype=np.float32).reshape(2,3,4)
            for name,sform_code,qform_code,expected_source in [('sform',1,1,'sform'),('qform',0,1,'qform'),('pixdim',0,0,'pixdim')]:
                image=nib.Nifti1Image(data,np.eye(4))
                sform=np.diag([-2.,3.,4.,1.]);sform[:3,3]=[11,12,13]
                qform=np.diag([-2.,3.,4.,1.]);qform[:3,3]=[21,22,23]
                image.set_sform(sform,code=sform_code);image.set_qform(qform,code=qform_code)
                image.header.set_zooms((2,3,4))
                path=Path(directory)/(name+'.nii.gz');nib.save(image,path)
                loaded=read_volume(path)
                expected={'sform':sform,'qform':qform,'pixdim':np.diag([2.,3.,4.,1.])}[expected_source]
                self.assertEqual(loaded.affine_source,expected_source)
                np.testing.assert_allclose(loaded.affine,expected,rtol=0,atol=1e-6)
                np.testing.assert_array_equal(loaded.data,data)
