import { OrthographicCamera, OrbitControls, shaderMaterial, useVideoTexture } from '@react-three/drei'
import { Canvas, extend, useThree, useFrame } from '@react-three/fiber'
import { useRef, useEffect, useState } from 'react'
import * as THREE from 'three'

import vertex from './shaders/4_30_2024/vertex.glsl'
import fragment from './shaders/4_30_2024/fragment.glsl'

const ShaderObjectMaterial = new shaderMaterial(
  {
    uTime: 0.0,
    uResolution: new THREE.Vector2( window.innerWidth, window.innerHeight ),
    uDiffuse: null
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

const ShaderObject = ({ cameraStream, isCamera }) => {
  const shaderObject = useRef()

  // Enable next line if this is a camera based shader
  // const cameraTexture = useVideoTexture(cameraStream)
  
  // Reload page is either the fragment or vertex shader files change
  useEffect(() => {
    if (shaderObject.current.material.fragmentShader !== fragment || shaderObject.current.material.vertexShader !== vertex)
      location.reload()
  })

  useEffect(() => {
    if (isCamera) {
      shaderObject.current.material.uDiffuse = cameraTexture
    }
  }, [])

  useFrame((state) => {
    shaderObject.current.material.uTime = state.clock.elapsedTime
  })

  return <mesh position={[ 0.5, 0.5, 0.0 ]}  scale={ 1.0 } ref={ shaderObject }>
    <planeGeometry args={[ 1.0, 1.0, ]} />
    <shaderObjectMaterial />
  </mesh>
}

const Scene = ({ isCamera }) => {
  useThree((state) => {
    state.camera.position.set(0, 0, 1)
  })

  return (<>
    <ShaderObject isCamera={ isCamera } />
  </>)
}

const CameraScene = ({ cameraStream, isCamera }) => {
  useThree((state) => {
    state.camera.position.set(0, 0, 1)
  })

  return (<>
    <ShaderObject cameraStream={ cameraStream } isCamera={ isCamera } />
  </>)
}

export default function App() {
  const [ cameraPermissionsGranted, setCameraPermissionsGranted ] = useState(false)
  const [ cameraStream, setCameraStream ] = useState()
  const isCamera = false

  const activeCamera = async () => {
    setCameraStream(await navigator.mediaDevices.getUserMedia({ video: true }))
    setCameraPermissionsGranted(true)
  }
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
        <Scene isCamera={ false } />
        {/* {
          cameraStream &&
            <CameraScene 
              isCamera={ true }
              cameraStream={ cameraStream }
            />
        } */}
      </Canvas>
      { isCamera && 
        <div style={{ 
          width: '100%', 
          position: 'absolute', 
          zIndex: 999, 
          bottom: 0, 
          left: 0, 
          right: 0, 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          margin: '0 auto', 
          padding: '0.5rem',
        }}>
          <button onClick={ activeCamera }>
            Grant Camera Permissions
          </button>
        </div>
      }
    </>
  )
}