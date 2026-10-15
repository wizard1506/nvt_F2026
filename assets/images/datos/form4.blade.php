<div style="position: relative; width: 100%; height: 100%; font-family: 'Helvetica', 'Arial', sans-serif; font-size: 12px;">

    {{-- Imagen de fondo: Posicionada absolutamente para no afectar el flujo del documento --}}
    <img src="data:image/png;base64,{{ base64_encode(file_get_contents(public_path('img/f4.png'))) }}"
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; image-rendering: high-quality;">

    {{-- Datos Personales --}}
    <div style="position: absolute; top: 125px; left: 100px;">{{ $cliente->paterno }}</div>
    <div style="position: absolute; top: 125px; left: 400px;">{{ $cliente->materno }}</div>
    <div style="position: absolute; top: 167px; left: 100px;">{{ $cliente->nombres }}</div>
    <div style="position: absolute; top: 167px; left: 400px;">{{ $cliente->casada }}</div>
    <div style="position: absolute; top: 167px; left: 580px;">{{ $cliente->prefijo }}</div>
    <div style="position: absolute; top: 210px; left: 400px;">{{ $cliente->documento }}</div>
    <div style="position: absolute; top: 210px; left: 580px;">{{ $cliente->extension }}</div>
    <div style="position: absolute; top: 201px; left: 190px;">{{ $cliente->tipo_documento }}</div>
    <div style="position: absolute; top: 215px; left: 190px;">{{ $cliente->nacionalidad }}</div>
    <div style="position: absolute; top: 229px; left: 190px;">{{ $cliente->fecha_nacimiento ? \Carbon\Carbon::parse($cliente->fecha_nacimiento)->format('d/m/Y') : '' }}</div>
    <div style="position: absolute; top: 241px; left: 190px;">{{ $cliente->estado_civil }}</div>
    <div style="position: absolute; top: 254px; left: 190px;">{{ $cliente->sexo }}</div>
    <div style="position: absolute; top: 267px; left: 190px;">{{ $cliente->nivel_estudio }}</div>
    <div style="position: absolute; top: 280px; left: 190px;">{{ $cliente->profesion }}</div>

    {{-- Datos de Vivienda --}}
    <div style="position: absolute; top: 293px; left: 320px;">{{ $cliente->tipo_vivienda }}</div>
    <div style="position: absolute; top: 293px; left: 500px;">{{ $cliente->tenencia }}</div>
    <div style="position: absolute; top: 328px; left: 70px;">{{ $cliente->costo_vivienda }}</div>
    <div style="position: absolute; top: 328px; left: 130px;">{{ $cliente->moneda_vivienda }}</div>
    <div style="position: absolute; top: 328px; left: 220px;">{{ $cliente->propietario }}</div>
    <div style="position: absolute; top: 328px; left: 550px;">{{ $cliente->telf_propietario }}</div>

    {{-- Datos de Localización --}}
    <div style="position: absolute; top: 363px; left: 100px;">{{ $cliente->pais }}</div>
    <div style="position: absolute; top: 363px; left: 275px;">{{ $cliente->dpto }}</div>
    <div style="position: absolute; top: 393px; left: 80px;">{{ $cliente->ciudad }}</div>
    <div style="position: absolute; top: 393px; left: 350px;">{{ $cliente->barrio }}</div>
    <div style="position: absolute; top: 433px; left: 80px;">{{ $cliente->avenida }}</div>
    <div style="position: absolute; top: 433px; left: 350px;">{{ $cliente->calle }}</div>
    <div style="position: absolute; top: 433px; left: 580px;">{{ $cliente->numero }}</div>

    {{-- Datos de Contacto --}}
    <div style="position: absolute; top: 483px; left: 200px;">{{ $cliente->telf_movil }}</div>
    <div style="position: absolute; top: 527px; left: 200px;">{{ $cliente->movil_oficina }}</div>
    <div style="position: absolute; top: 483px; left: 60px;">{{ $cliente->telf_fijo }}</div>
    <div style="position: absolute; top: 527px; left: 60px;">{{ $cliente->fijo_oficina }}</div>
    <div style="position: absolute; top: 570px; left: 60px;">{{ $cliente->correo }}</div>

    {{-- Datos Laborales --}}
    <div style="position: absolute; top: 483px; left: 350px;">{{ $cliente->empresa }}</div>
    <div style="position: absolute; top: 527px; left: 350px;">{{ $cliente->direccion }}</div>
    <div style="position: absolute; top: 570px; left: 350px;">{{ $cliente->rubro }}</div>
    <div style="position: absolute; top: 570px; left: 565px;">{{ $cliente->ingresos }}</div>
    <div style="position: absolute; top: 570px; left: 620px;">{{ $cliente->moneda_ingresos }}</div>

    {{-- Referencias Personales --}}
    <div style="position: absolute; top: 620px; left: 60px;">{{ $cliente->referencia1 }}</div>
    <div style="position: absolute; top: 620px; left: 350px;">{{ $cliente->relacion1 }}</div>
    <div style="position: absolute; top: 620px; left: 565px;">{{ $cliente->telf_ref1 }}</div>
    <div style="position: absolute; top: 660px; left: 60px;">{{ $cliente->referencia2 }}</div>
    <div style="position: absolute; top: 660px; left: 350px;">{{ $cliente->relacion2 }}</div>
    <div style="position: absolute; top: 660px; left: 565px;">{{ $cliente->telf_ref2 }}</div>

    {{-- Observaciones --}}
    <div style="position: absolute; top: 862px; left: 140px; width: 450px; white-space: normal;">{{ $cliente->obs1 }}</div>
    <div style="position: absolute; top: 878px; left: 140px; width: 450px; white-space: normal;">{{ $cliente->obs2 }}</div>

    {{-- Datos Adicionales --}}
    <div style="position: absolute; top: 957px; left: 105px;">{{ $nombreCompleto }}</div>
    <div style="position: absolute; top: 957px; left: 485px;">{{ $cliente->usuario->nombres_apellidos ?? 'Asesor no asignado' }}</div>
</div>