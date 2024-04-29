import { OrthographicCamera, OrbitControls, shaderMaterial } from '@react-three/drei'
import { Canvas, extend, useThree, useFrame } from '@react-three/fiber'
import { useRef, useEffect, useState } from 'react'
import * as THREE from 'three'

import vertex from './shaders/drawing/vertex.glsl'
import fragment from './shaders/drawing/fragment.glsl'

const ShaderObjectMaterial = new shaderMaterial(
  {
    uTime: 0.0,
    uResolution: new THREE.Vector2( window.innerWidth, window.innerHeight ) 
  },
  vertex,
  fragment
)
extend({ ShaderObjectMaterial })

// Reload page once user is finished resizing the window
const debounce = (func) => {
  var timer
  return (event) => {
    if (timer) clearTimeout(timer)
    timer = setTimeout(func, 100, event)
  }
}
window.addEventListener('resize', debounce(function(e) { location.reload() }))

const ShaderObject = () => {
  const shaderObject = useRef()

  // Reload page is either the fragment or vertex shader files change
  useEffect(() => {
    if (shaderObject.current.material.fragmentShader !== fragment || shaderObject.current.material.vertexShader !== vertex)
      location.reload()
  })

  useFrame((state) => {
    shaderObject.current.material.uTime = state.clock.elapsedTime
  })

  return <mesh position={[ 0.5, 0.5, 0.0 ]} ref={ shaderObject }>
    <planeGeometry args={[ 1.0, 1.0, ]} />
    <shaderObjectMaterial />
  </mesh>
}

const Scene = () => {
  useThree((state) => {
    state.camera.position.set(0, 0, 1)
  })

  return (<>
    <ShaderObject />
  </>)
}

export default function App() {
  const [ use, setUse ] = useState(0)
  useEffect(() => {
  }, [])
  return (
    <>
      <Canvas>
        {/* <OrbitControls /> */}
        <OrthographicCamera
          makeDefault
          top={ 1 }
          left={ 0 }
          right={ 1 }
          bottom={ 0 }
          near={ 0.1 }
          far={ 1000 }
        />
        <Scene />
      </Canvas>
    </>
  )
}