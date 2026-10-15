<div style="position: relative; width: 100%; height: 100%; font-family: Arial, sans-serif; font-size: 12px;">

    {{-- Imagen de fondo: Posicionada absolutamente para no afectar el flujo del documento --}}
    <img src="data:image/png;base64,{{ base64_encode(file_get_contents(public_path('img/f3.png'))) }}"
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; image-rendering: high-quality;">

    {{-- Datos posicionados absolutamente sobre la imagen --}}
    <div style="position: absolute; top: 140px; left: 65px; font-size: 16px; text-align: center;">{{ $dia ?? '' }}</div>
    <div style="position: absolute; top: 140px; left: 132px; font-size: 16px; text-align: center;">{{ $mes ?? '' }}</div>
    <div style="position: absolute; top: 140px; left: 188px; font-size: 16px; text-align: center;">{{ $anio ?? '' }}</div>

    {{-- Para centrar el texto, usamos un div con ancho y text-align center --}}
    <div style="position: absolute; top: 220px; left: -85px; width: 550px; font-size: 18px; text-align: center;">{{ $cliente->urbanizacion }}</div>

    <div style="position: absolute; top: 300px; left: 90px;">{{ $cliente->proyecto }}</div>
    <div style="position: absolute; top: 300px; left: 210px;">{{ $cliente->uv }}</div>
    <div style="position: absolute; top: 300px; left: 340px;">{{ $cliente->mz }}</div>
    <div style="position: absolute; top: 300px; left: 460px;">{{ $cliente->lt }}</div>
    <div style="position: absolute; top: 300px; left: 600px;">{{ $cliente->cat }}</div>

    <div style="position: absolute; top: 400px; left: 70px;">{{ $cliente->plazo_contado }}</div>
    <div style="position: absolute; top: 400px; left: 210px;">{{ $cliente->mt2 }}</div>
    <div style="position: absolute; top: 400px; left: 470px;">{{ $cliente->cantidad_plazo }}</div>

    <div style="position: absolute; top: 453px; left: 67px;">{{ $nombreCompleto }}</div>
    <div style="position: absolute; top: 453px; left: 552px;">{{ $cliente->documento }}</div>
    <div style="position: absolute; top: 468px; left: 82px;">{{ $cliente->extension }}</div>

    <div style="position: absolute; top: 775px; left: 121px;">{{ $nombreCompleto }}</div>

</div>