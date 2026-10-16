# SPDX-License-Identifier: GPL-3.0-or-later
"""Fail early when a CI runner cannot draw a real off-screen VTK frame."""
import argparse
import json
import platform


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-software', action='store_true')
    args = parser.parse_args()
    import numpy as np
    import pyvista as pv

    plot = pv.Plotter(off_screen=True, window_size=(64, 64))
    try:
        plot.set_background('white')
        plot.add_mesh(pv.Sphere(theta_resolution=12, phi_resolution=12), color='red')
        window = plot.render_window
        window.Render()
        capabilities = window.ReportCapabilities()
        device = next((line.split(':', 1)[1].strip() for line in capabilities.splitlines()
                       if 'OpenGL renderer string:' in line), '')
        image = plot.screenshot(return_img=True)
        assert window.SupportsOpenGL(), 'VTK reports no working OpenGL context.'
        assert device, 'The native renderer did not report a drawing device.'
        assert image.shape[:2] == (64, 64), image.shape
        assert np.ptp(image[:, :, :3].astype(float), axis=(0, 1)).max() > 32, 'Blank native frame.'
        if args.require_software:
            assert window.GetClassName() == 'vtkEGLRenderWindow', window.GetClassName()
            assert 'llvmpipe' in device.lower(), device
        print(json.dumps({'python': platform.python_version(), 'vtk': pv.vtk_version_info,
                          'window': window.GetClassName(), 'device': device,
                          'frame': list(image.shape), 'passed': True}), flush=True)
    finally:
        plot.close()
        plot.deep_clean()


if __name__ == '__main__':
    main()
