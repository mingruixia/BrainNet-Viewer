classdef TestFigureAnnotationControls < matlab.unittest.TestCase
    % Global annotations use the same image settings as rendering and presets.
    methods (Test)
        function stagesAppliesAndRestoresAnnotations(t)
            f=uifigure('Visible','off');cleanupFigure=onCleanup(@()delete(f)); %#ok<NASGU>
            initial=brainnet.core.VisualizationSettings().withPatch(struct('image', ...
                struct('title','Original title','colorbar_label','Original units', ...
                'colorbar_location','eastoutside','show_colorbar',false,'width',1234)));
            setappdata(f,'accepted',initial);
            editor=brainnet.app.VisualizationSettingsAccordion(f,initial, ...
                ApplyCallback=@(settings)setappdata(f,'accepted',settings));
            cleanupEditor=onCleanup(@()delete(editor)); %#ok<NASGU>
            editor.selectCategory('global');
            title=findall(f,'Tag','ImageTitle');
            label=findall(f,'Tag','ImageColorbarLabel');
            location=findall(f,'Tag','ImageColorbarLocation');
            show=findall(f,'Tag','ImageShowColorbar');
            t.assertNumElements(title,1);
            t.assertNumElements(label,1);t.assertNumElements(location,1);t.assertNumElements(show,1);
            t.verifyEqual(location.ItemsData,{'eastoutside','westoutside','southoutside','northoutside'});
            t.verifyEqual(title.Value,'Original title');
            title.Value='Condition A — 脑网络';
            label.Value='Correlation';location.Value='southoutside';show.Value=true;
            t.verifyEqual(getappdata(f,'accepted').toStruct(),initial.toStruct());
            apply=findall(f,'Tag','SettingsApply');apply.ButtonPushedFcn(apply,[]);
            accepted=getappdata(f,'accepted');image=accepted.section('image');
            t.verifyEqual(image.title,'Condition A — 脑网络');
            t.verifyEqual(image.colorbar_label,'Correlation');
            t.verifyEqual(image.colorbar_location,'southoutside');
            t.verifyTrue(image.show_colorbar);t.verifyEqual(image.width,1234);
            title.Value='Unapplied title';
            label.Value='Unapplied units';location.Value='northoutside';show.Value=false;
            revert=findall(f,'Tag','SettingsRevert');revert.ButtonPushedFcn(revert,[]);
            t.verifyEqual(title.Value,image.title);
            t.verifyEqual(label.Value,image.colorbar_label);t.verifyEqual(location.Value,image.colorbar_location);
            t.verifyTrue(show.Value);
            preset=brainnet.core.VisualizationPreset(accepted);
            restored=brainnet.core.VisualizationPreset.fromStruct(jsondecode(jsonencode(preset.toStruct())));
            editor.replaceSettings(restored.Settings);
            t.verifyEqual(title.Value,image.title);
            t.verifyEqual(label.Value,image.colorbar_label);t.verifyEqual(location.Value,image.colorbar_location);
            t.verifyTrue(show.Value);
            title.Value='';apply.ButtonPushedFcn(apply,[]);
            t.verifyEmpty(getappdata(f,'accepted').section('image').title);
        end
    end
end
