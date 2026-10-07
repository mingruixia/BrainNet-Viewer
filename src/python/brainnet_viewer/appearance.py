"""Material settings adapted to VTK; raster output is not MATLAB pixel-equivalent."""
import numpy as np


def material(settings):
    profiles={"dull":[.3,.8,0,10,1],"shiny":[.3,.6,.9,20,1],"metal":[.3,.3,1,25,.5],"default":[.3,.6,.9,10,1]}
    profile=settings["material_profile"]
    if profile=="custom":
        coefficients=np.asarray(settings["material_coefficients"],dtype=float)
        if coefficients.shape not in ((3,),(4,),(5,)) or not np.isfinite(coefficients).all() or ((coefficients[:3]<0)|(coefficients[:3]>1)).any():
            raise ValueError("Material needs three strengths in [0,1] and optional exponent/reflectance.")
        if len(coefficients)>3 and not 0<=coefficients[3]<=128: raise ValueError("VTK supports a specular exponent in [0,128].")
        if len(coefficients)==5 and not 0<=coefficients[4]<=1: raise ValueError("Specular color reflectance must be in [0,1].")
        coefficients=list(coefficients)
        if len(coefficients)==3: coefficients.append(10)
        if len(coefficients)==4: coefficients.append(1)
    elif profile in profiles: coefficients=profiles[profile]
    else: raise ValueError("Unsupported material profile.")
    lighting=settings["lighting"]
    if lighting not in ("none","flat","gouraud","phong"): raise ValueError("Unsupported lighting mode.")
    return dict(ambient=float(coefficients[0]),diffuse=float(coefficients[1]),specular=float(coefficients[2]),
                specular_power=float(coefficients[3]),reflectance=float(coefficients[4]),lighting=lighting)


SPECULAR_DECLARATION = "vec3 specularColor = specularIntensity * specularColorUniform;"


def apply_material(actor, values):
    """Apply lighting to scientific actors; preserve geometry, colors and opacity."""
    prop=actor.GetProperty()
    prop.SetAmbient(values["ambient"]); prop.SetDiffuse(values["diffuse"])
    prop.SetSpecular(values["specular"]); prop.SetSpecularPower(values["specular_power"])
    prop.SetLighting(values["lighting"]!="none")
    interpolation={"flat":prop.SetInterpolationToFlat,"gouraud":prop.SetInterpolationToGouraud,
                   "phong":prop.SetInterpolationToPhong}
    if values["lighting"] in interpolation: interpolation[values["lighting"]]()
    reflectance=values["reflectance"]
    prop.SetSpecularColor(1,1,1)
    shader=actor.GetShaderProperty()
    shader.ClearFragmentShaderReplacement(SPECULAR_DECLARATION,False)
    if values["lighting"]=="none" or values["specular"]==0 or reflectance==1: return
    mapper=actor.GetMapper()
    if not mapper.GetScalarVisibility():
        color=np.asarray(prop.GetDiffuseColor())
        prop.SetSpecularColor(*(reflectance+(1-reflectance)*color))
        return
    # These actors use point RGB(A) or the point-scalar lookup table. Replace
    # the declaration after VTK's standard substitutions, so unlit picking
    # shaders without that declaration do not receive a lighting expression.
    if mapper.GetColorMode()==2 or not mapper.GetInterpolateScalarsBeforeMapping():
        base="vertexColorVSOutput.rgb"
    else:
        base="texture(colortexture, colorTCoordVCVSOutput.st).rgb"
    expression=f"vec3 specularColor = specularIntensity * mix({base}, vec3(1.0), {reflectance!r});"
    shader.AddFragmentShaderReplacement(SPECULAR_DECLARATION,False,expression,False)
