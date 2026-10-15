<div style="position: relative; width: 100%; height: 100%; font-family: Arial, sans-serif; font-size: 12px;">

    {{-- Imagen de fondo: Posicionada absolutamente para no afectar el flujo del documento --}}
    <img src="data:image/png;base64,{{ base64_encode(file_get_contents(public_path('img/f1.png'))) }}"
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; image-rendering: high-quality;">

    {{-- Los datos se imprimen en divs posicionados absolutamente sobre la imagen --}}
    <div style="position: absolute; top: 70px; left: 270px;">{{ $cliente->urbanizacion }}</div>
    <div style="position: absolute; top: 110px; left: 180px;">{{ $cliente->nombres }} {{ $cliente->paterno }} {{ $cliente->materno }} {{$cliente->prefijo}} {{$cliente->casada}} </div>
    <div style="position: absolute; top: 144px; left: 210px;">{{ $cliente->documento }}</div>
    <div style="position: absolute; top: 144px; left: 415px;">{{ $cliente->extension }}</div>

    {{-- Imagen de Check --}}
    @if ($cliente->plazo_contado == 'PLAZO')
    <img src="data:image/jpeg;base64,{{ base64_encode(file_get_contents(public_path('img/check1.jpg'))) }}"
        style="position: absolute; top: 170px; left: 280px; width: 25px; height: 25px;">
    @elseif ($cliente->plazo_contado == 'CONTADO')
    <img src="data:image/jpeg;base64,{{ base64_encode(file_get_contents(public_path('img/check1.jpg'))) }}"
        style="position: absolute; top: 170px; left: 400px; width: 25px; height: 25px;">
    @endif

    <div style="position: absolute; top: 210px; left: 115px;">{{ $cliente->proyecto }}</div>
    <div style="position: absolute; top: 210px; left: 235px;">{{ $cliente->uv }}</div>
    <div style="position: absolute; top: 210px; left: 370px;">{{ $cliente->mz }}</div>
    <div style="position: absolute; top: 210px; left: 480px;">{{ $cliente->lt }}</div>
    <div style="position: absolute; top: 210px; left: 625px;">{{ $cliente->cat }}</div>

    {{-- Datos del Asesor (Usuario) --}}
    <div style="position: absolute; top: 253px; left: 70px;">{{ $cliente->usuario->nombres_apellidos ?? '' }}</div>
    <div style="position: absolute; top: 253px; left: 550px;">{{ $cliente->usuario->codigo_asesor ?? '' }}</div>
</div>