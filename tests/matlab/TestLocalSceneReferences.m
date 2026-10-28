classdef TestLocalSceneReferences < matlab.unittest.TestCase
    properties
        Root string
        DataRoot string
        Folder string
    end
    methods(TestMethodSetup)
        function setup(t)
            t.Root=string(getenv('BNV_PROJECT_ROOT'));
            t.assertNotEqual(t.Root,"");
            t.DataRoot=fullfile(t.Root,'src','matlab','BrainNetViewer');
            addpath(t.Root,t.DataRoot);
            evidence=fullfile(t.Root,'validation','local-scene-reference-20261027');
            if ~isfolder(evidence),mkdir(evidence);end
            t.Folder=string(tempname(evidence));
            mkdir(t.Folder);
        end
    end
    methods(Test)
        function localSelectionDoesNotStageOrNeedApproval(t)
            source=t.makeSurface();hash=brainnet.io.internal.sha256File(source);
            a=brainnet.app.BrainNetApp(t.DataRoot,Visible=false);done=onCleanup(@() delete(a));
            a.selectInputPath('surface',source);
            ref=a.Session.Scene.inputByRole('surface');
            t.verifyEqual(ref.resolve(t.DataRoot),string(char(java.io.File(char(source)).getCanonicalPath())));
            t.verifyEqual(ref.Sha256,hash);t.verifyFalse(isfield(ref.Metadata,'external_import'));
            a.loadCurrentScene();t.verifyEqual(a.Session.Data.surface.VertexCount,3);
            a.selectInputPath('surface',source,ExternalImportApproved=true);
            t.verifyEqual(a.Session.Scene.Inputs{1}.LocalPath,ref.LocalPath);
            t.verifyEqual(brainnet.io.internal.sha256File(source),hash);
            t.verifyError(@() brainnet.core.InputReference('surface','../escape.nv'),'BNV:Core:ParentTraversal');
            t.verifyError(@() brainnet.core.InputReference('surface','/absolute.nv'),'BNV:Core:AbsolutePath');
            t.verifyError(@() brainnet.core.InputReference('surface','a.nv',LocalPath='relative.nv'),'BNV:Core:InvalidLocalPath');
        end
        function ordinarySceneReferencesOriginalAndLegacyStillResolves(t)
            source=t.makeSurface();a=brainnet.app.BrainNetApp(t.DataRoot,Visible=false);done=onCleanup(@() delete(a));
            save=findall(a.UIFigure,'Tag','SaveScene');t.assertNumElements(save,1);
            t.verifyTrue(contains(string(save.Tooltip),'JSON saves file paths on this computer'));
            t.verifyTrue(contains(string(save.Tooltip),'Portable Scene with data (*.zip)'));
            a.selectInputPath('surface',source);folder=fullfile(t.Folder,'documents');mkdir(folder);
            path=fullfile(folder,'local.json');a.saveSceneFile(path);
            listing=dir(folder);t.verifyEqual(sum(~[listing.isdir]),1);t.verifyEqual(sum([listing.isdir]),2);
            clone=brainnet.io.readScene(path);t.verifyEqual(clone.Inputs{1}.LocalPath,a.Session.Scene.Inputs{1}.LocalPath);
            session=brainnet.app.SceneSession(t.DataRoot);session.loadScene(clone);t.verifyEqual(session.Data.surface.VertexCount,3);
            [~,name,ext]=fileparts(source);
            old=brainnet.core.Scene('Legacy','Legacy root-relative',1,0,{brainnet.core.InputReference('surface',name+ext)});
            legacyPath=fullfile(t.Folder,'legacy.json');brainnet.io.writeScene(old,legacyPath,t.Folder);
            t.verifyFalse(isfield(jsondecode(fileread(legacyPath)).inputs.surface,'local_path'));
            legacy=brainnet.app.SceneSession(t.Folder);legacy.loadScene(brainnet.io.readScene(legacyPath));
            t.verifyEqual(legacy.Data.surface.VertexCount,3);
        end
        function explicitPortableZipRelocatesWithoutOriginals(t)
            source=t.makeSurface();a=brainnet.app.BrainNetApp(t.DataRoot,Visible=false);done=onCleanup(@() delete(a));
            a.selectInputPath('surface',source);path=fullfile(t.Folder,'portable.zip');a.saveSceneFile(path);
            moved=fullfile(t.Folder,'moved');mkdir(moved);copyfile(path,fullfile(moved,'scene.zip'));delete(source);
            clone=brainnet.io.readScene(fullfile(moved,'scene.zip'));
            t.verifyEqual(clone.Inputs{1}.Sha256,a.Session.Scene.Inputs{1}.Sha256);
            t.verifyNotEqual(clone.Inputs{1}.LocalPath,a.Session.Scene.Inputs{1}.LocalPath);
            session=brainnet.app.SceneSession(t.DataRoot);session.loadScene(clone);t.verifyEqual(session.Data.surface.VertexCount,3);
            again=brainnet.io.readScene(fullfile(moved,'scene.zip'));t.verifyEqual(again.toStruct(),clone.toStruct());
            a.importSceneFile(fullfile(moved,'scene.zip'));a.loadCurrentScene();
            t.verifyEqual(a.Session.Data.surface.FaceCount,1);
            t.verifyEqual(a.snapshot().export_settings,clone.Metadata.session_state.export);
        end
        function externalGiftiCompanionTravelsAndIsVerified(t)
            folder=fullfile(t.Folder,'payload');mkdir(folder);
            file=fullfile(folder,'geometry.bin');fid=fopen(file,'w','ieee-le');
            fwrite(fid,[0 0 0 1 0 0 0 1 0],'single');fwrite(fid,[0 1 2],'int32');fclose(fid);
            source=fullfile(t.Folder,'external.gii');
            xml=['<GIFTI Version="1.0" NumberOfDataArrays="2">' ...
                '<DataArray Intent="NIFTI_INTENT_POINTSET" DataType="NIFTI_TYPE_FLOAT32" ArrayIndexingOrder="RowMajorOrder" Dimensionality="2" Dim0="3" Dim1="3" Encoding="ExternalFileBinary" Endian="LittleEndian" ExternalFileName="payload/geometry.bin" ExternalFileOffset="0"><Data/></DataArray>' ...
                '<DataArray Intent="NIFTI_INTENT_TRIANGLE" DataType="NIFTI_TYPE_INT32" ArrayIndexingOrder="RowMajorOrder" Dimensionality="2" Dim0="1" Dim1="3" Encoding="ExternalFileBinary" Endian="LittleEndian" ExternalFileName="payload/geometry.bin" ExternalFileOffset="36"><Data/></DataArray></GIFTI>'];
            fid=fopen(source,'w');fwrite(fid,xml);fclose(fid);
            ref=brainnet.core.InputReference('surface','external.gii',LocalPath=source);
            scene=brainnet.core.Scene('Gifti','External GIfTI',1,0,{ref});
            path=fullfile(t.Folder,'gifti.zip');brainnet.io.writePortableScene(scene,path,t.DataRoot);
            clone=brainnet.io.readScene(path);mesh=brainnet.io.readGifti(clone.Inputs{1},t.DataRoot);
            t.verifyEqual(mesh.Coordinates,[0 0 0;1 0 0;0 1 0]);
            data=fullfile(fileparts(clone.Inputs{1}.LocalPath),'payload','geometry.bin');
            t.verifyEqual(brainnet.io.internal.sha256File(data),brainnet.io.internal.sha256File(file));
            fid=fopen(data,'a');fwrite(fid,uint8(1));fclose(fid);
            t.verifyError(@() brainnet.io.readScene(path),'BNV:IO:ChecksumMismatch');
            unsafe=fullfile(t.Folder,'unsafe.gii');fid=fopen(unsafe,'w');
            fwrite(fid,'<!DOCTYPE GIFTI [<!ENTITY x SYSTEM "file:///not-to-be-read">]><GIFTI/>');fclose(fid);
            t.verifyError(@() brainnet.io.internal.inputCompanions(unsafe),'BNV:IO:UnsafeGiftiXml');
        end
        function failedPackagePreservesExistingAndLocalJsonSealsHash(t)
            source=t.makeSurface();ref=brainnet.core.InputReference('surface','outside.nv',LocalPath=source,Sha256=repmat('0',1,64));
            bad=brainnet.core.Scene('Bad','Bad input',1,0,{ref});
            path=fullfile(t.Folder,'keep.zip');fid=fopen(path,'w');fwrite(fid,'existing');fclose(fid);before=brainnet.io.internal.sha256File(path);
            t.verifyError(@() brainnet.io.writePortableScene(bad,path,t.DataRoot,Overwrite=true),'BNV:IO:ChecksumMismatch');
            t.verifyEqual(brainnet.io.internal.sha256File(path),before);
            ref=brainnet.core.InputReference('surface','outside.nv',LocalPath=source);
            scene=brainnet.core.Scene('Good','Good input',1,0,{ref});j=fullfile(t.Folder,'local.json');saved=brainnet.io.writeScene(scene,j,t.DataRoot);
            t.verifyEqual(saved.Inputs{1}.Sha256,brainnet.io.internal.sha256File(source));
            t.verifyError(@() brainnet.io.writePortableScene(scene,path,t.DataRoot),'BNV:IO:OutputExists');
        end
        function archiveTraversalAndDuplicateAreRejected(t)
            path=fullfile(t.Folder,'traversal.zip');t.rawZip(path,{'../outside.txt'},{'bad'});
            t.verifyError(@() brainnet.io.readScene(path),'BNV:IO:SceneZipEntry');
            path=fullfile(t.Folder,'duplicate.zip');t.rawZip(path,{'assets/X','assets/x'},{'a','b'});
            t.verifyError(@() brainnet.io.readScene(path),'BNV:IO:SceneZipDuplicate');
            t.verifyFalse(isfile(fullfile(fileparts(t.Folder),'outside.txt')));
        end
        function failedPortableOpenKeepsCurrentInputsAndNoHostPath(t)
            source=t.makeSurface();a=brainnet.app.BrainNetApp(t.DataRoot,Visible=false);done=onCleanup(@() delete(a));
            a.selectInputPath('surface',source);before=a.Session.Scene.toStruct();
            bad=before;bad.metadata.input_base='scene-directory';path=fullfile(t.Folder,'host-reference.zip');
            t.rawZip(path,{'scene.json'},{jsonencode(bad)});
            t.verifyError(@() a.importSceneFile(path),'BNV:IO:PortableLocalPath');
            t.verifyEqual(a.Session.Scene.toStruct(),before);
        end
        function pairedNiftiFilesTravelAndMissingCompanionProtectsOutput(t)
            header=fullfile(t.Folder,'paired.hdr');image=fullfile(t.Folder,'paired.img');
            fid=fopen(header,'w');fwrite(fid,uint8(1:20));fclose(fid);
            fid=fopen(image,'w');fwrite(fid,uint8(21:40));fclose(fid);
            ref=brainnet.core.InputReference('volume','paired.hdr',LocalPath=header);
            scene=brainnet.core.Scene('Pair','Paired payload only',8,2,{ref});
            path=fullfile(t.Folder,'pair.zip');brainnet.io.writePortableScene(scene,path,t.DataRoot);
            clone=brainnet.io.readScene(path);copy=fullfile(fileparts(clone.Inputs{1}.LocalPath),'paired.img');
            t.verifyEqual(brainnet.io.internal.sha256File(copy),brainnet.io.internal.sha256File(image));
            before=brainnet.io.internal.sha256File(path);delete(image);
            t.verifyError(@() brainnet.io.writePortableScene(scene,path,t.DataRoot,Overwrite=true),'BNV:IO:PackageCompanionMissing');
            t.verifyEqual(brainnet.io.internal.sha256File(path),before);
        end
        function canvasCameraAndExportSurviveBothSaveModes(t)
            source=fullfile(t.Folder,'real external.nv');copyfile(fullfile(t.DataRoot,'Data','SurfTemplate','BrainMesh_ICBM152.nv'),source);
            a=brainnet.app.BrainNetApp(t.DataRoot,Visible=false);done=onCleanup(@() delete(a));
            a.selectInputPath('surface',source);a.loadCurrentScene();a.renderCurrentScene(Target='embedded');
            axis=a.BatchRenderer.ActiveAxes(1);camorbit(axis,9,3,'camera');a.BatchRenderer.synchronizeInteraction(axis);
            camera=a.BatchRenderer.captureCamera();target=a.BatchRenderer.ActiveTarget;
            a.configureExport(Format='png',Width=800,Height=600,Units='pixels',Resolution=200,BackgroundColor='none');
            path=fullfile(t.Folder,'render.zip');a.saveSceneFile(fullfile(t.Folder,'render.json'));a.saveSceneFile(path);
            t.verifyTrue(isgraphics(target));t.verifyEqual(a.BatchRenderer.captureCamera(),camera,'AbsTol',1e-9);
            clone=brainnet.io.readScene(path);t.verifyEqual(clone.Metadata.session_state.camera,camera,'AbsTol',1e-9);
            t.verifyEqual(string(clone.Metadata.session_state.scene_signature),brainnet.core.SessionState.signature(clone));
            output=fullfile(t.Folder,'external.png');a.exportCurrentFigure(output);
            [~,~,alpha]=imread(output);t.verifyNotEmpty(alpha);
            record=fileread(output+'.provenance.json');t.verifyFalse(contains(record,char(t.Folder)));
            t.verifyFalse(contains(record,'local_path'));
            t.verifyEqual(a.BatchRenderer.captureCamera(),camera,'AbsTol',1e-9);
            sanitized=brainnet.io.internal.sceneForProvenance(a.Session.Scene);t.verifyFalse(isfield(sanitized.inputs.surface,'local_path'));
        end
    end
    methods(Access=private)
        function path=makeSurface(t)
            path=fullfile(t.Folder,'external space.nv');fid=fopen(path,'w');
            fprintf(fid,'3\n0 0 0\n1 0 0\n0 1 0\n1\n1 2 3\n');fclose(fid);
        end
        function rawZip(~,path,names,contents)
            stream=java.util.zip.ZipOutputStream(java.io.FileOutputStream(char(path)));
            done=onCleanup(@() stream.close());
            for k=1:numel(names)
                stream.putNextEntry(java.util.zip.ZipEntry(names{k}));
                stream.write(typecast(uint8(unicode2native(contents{k},'UTF-8')),'int8'));stream.closeEntry();
            end
        end
    end
end
