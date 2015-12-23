#include <getopt.h>
#include <iomanip>
#include <iostream>
#include "../include/ecuda/device.hpp"

std::string create_memory_string( unsigned long x );
std::string create_frequency_string( const unsigned x );

int main( int argc, char* argv[] )
{

	int deviceCount = ecuda::device::get_device_count();

	if( deviceCount == 1 )
		std::cout << "There is " << deviceCount << " device supporting ecuda." << std::endl;
	else
		std::cout << "There are " << deviceCount << " devices supporting ecuda." << std::endl;
	std::cout << std::endl;

	for( int i = 0; i < deviceCount; ++i ) {

		ecuda::device device( i );
		const cudaDeviceProp& prop = device.get_properties();

		std::cout << "========================================================================" << std::endl;
		std::cout << "::Device " << i << " is a: " << prop.name << std::endl;
		std::cout << "------------------------------------------------------------------------" << std::endl;
		std::cout << "Version    :: CUDA Driver: " << device.get_driver_version_string() << " CUDA Runtime: " << device.get_runtime_version_string() << " Compute Capability: " << prop.major << "." << prop.minor << std::endl;
		std::cout << "Memory     :: Global: " << create_memory_string(prop.totalGlobalMem) << " Constant: " << create_memory_string(prop.totalConstMem) << std::endl;
		std::cout << "              Shared Per Block: " << create_memory_string(prop.sharedMemPerBlock) << " L2 Cache: " << create_memory_string(prop.l2CacheSize) << std::endl;
		std::cout << "              Bus Width: " << create_memory_string(prop.memoryBusWidth) << std::endl;
		std::cout << "Number     :: Multiprocessors: " << prop.multiProcessorCount << " Warp Size: " << prop.warpSize << " (=Cores: " << (prop.warpSize*prop.multiProcessorCount) << ")" << std::endl;
		std::cout << "              Maximum Threads Per Block: " << prop.maxThreadsPerBlock << " Asynchronous Engines: " << prop.asyncEngineCount << std::endl;
		std::cout << "Dimension  :: Block: [" << prop.maxThreadsDim[0] << " x " << prop.maxThreadsDim[1] << " x " << prop.maxThreadsDim[2] << "] Grid: [" << prop.maxGridSize[0] << " x " << prop.maxGridSize[1] << " x " << prop.maxGridSize[2] << "]" << std::endl;
		std::cout << "Texture    :: Alignment: " << create_memory_string(prop.textureAlignment) << " Pitch Alignment: " << create_memory_string(prop.texturePitchAlignment) << std::endl;
		std::cout << "Surface    :: Alignment: " << create_memory_string(prop.surfaceAlignment) << std::endl;
		std::cout << "Other      :: Registers Per Block: " << prop.regsPerBlock << " Maximum Memory Pitch: " << create_memory_string(prop.memPitch) << std::endl;
		std::cout << "              Concurrent kernels: " << prop.concurrentKernels << std::endl;
		std::cout << "              Maximum Threads Per Multiprocessor: " << prop.maxThreadsPerMultiProcessor << std::endl;
		std::cout << "Clock Rate :: GPU: " << create_frequency_string(prop.clockRate*1000) << " Memory: " << create_frequency_string(prop.memoryClockRate) << std::endl;
		std::cout << "Features   :: Concurrent copy and execution            [" << (prop.deviceOverlap?'Y':'N')            << "]" << std::endl;
		std::cout << "              Run time limit on kernels                [" << (prop.kernelExecTimeoutEnabled?'Y':'N') << "]" << std::endl;
		std::cout << "              Integrated                               [" << (prop.integrated?'Y':'N')               << "]" << std::endl;
		std::cout << "              Host page-locked memory                  [" << (prop.canMapHostMemory?'Y':'N')         << "]" << std::endl;
		std::cout << "              ECC enabled                              [" << (prop.ECCEnabled?'Y':'N')               << "]" << std::endl;
		std::cout << "              Shares a unified address space with host [" << (prop.unifiedAddressing?'Y':'N')        << "]" << std::endl;
		std::cout << "              Tesla device using TCC driver            [" << (prop.tccDriver?'Y':'N')                << "]" << std::endl;
		std::cout << "PCI        :: Domain: " << prop.pciDomainID << " Bus: " << prop.pciBusID << " Device: " << prop.pciDeviceID << std::endl;
		std::cout << "------------------------------------------------------------------------" << std::endl;
		std::cout << "Compute mode:" << std::endl;
		std::cout << "  Default     meaning: multiple threads can use cudaSetDevice()  [" << (prop.computeMode==cudaComputeModeDefault?'X':' ')    << "]" << std::endl;
		std::cout << "  Exclusive   meaning: only one thread can use cudaSetDevice()   [" << (prop.computeMode==cudaComputeModeExclusive?'X':' ')  << "]" << std::endl;
		std::cout << "  Prohibited  meaning: no threads can use cudaSetDevice()        [" << (prop.computeMode==cudaComputeModeProhibited?'X':' ') << "]" << std::endl;
		std::cout << "========================================================================" << std::endl;
		std::cout << std::endl;

	}

	return EXIT_SUCCESS;

}

///
/// \brief Performs a unit conversion and creates a pretty string.
///
/// If the provided value is an exact multiple of per_unit then no
/// decimal places will be displayed, regardless of the value of digits.
/// (e.g. digits=2 x=2000 per_unit=1000 unitSymbol="k" gives: 2k
///       digits=2 x=2500 per_unit=1000 unitSymbol="k" gives: 2.50k)
///
/// If x < per_unit then the function returns false so that the
/// user can retry with a smaller unit.
///
/// \param out stream to output formatted string to
/// \param digits number of decimal places
/// \param x the value to format
/// \param per_unit the value per unit (e.g. 2^30=1Gb)
/// \param unitSymbol the symbol for the unit (e.g. "Gb")
/// \return true if the string was successfully created
///
bool try_creating_unit_string( std::ostream& out, unsigned digits, unsigned long x, unsigned long per_unit, const std::string& unitSymbol = std::string() )
{
	unsigned long units = x / per_unit;
	if( !units ) return false;
	std::stringstream ss;
	if( x % per_unit ) {
		const double y = x / static_cast<double>(per_unit);
		ss << std::setprecision(digits) << std::fixed << y;
	} else {
		ss << units;
	}
	ss << unitSymbol;
	out << ss.str();
	return true;
}

std::string create_memory_string( unsigned long x )
{
	std::stringstream ss;
	if( try_creating_unit_string( ss, 1, x, 1073741824, "Gb" ) ) return ss.str();
	if( try_creating_unit_string( ss, 1, x, 1048576   , "Mb" ) ) return ss.str();
	if( try_creating_unit_string( ss, 1, x, 1024      , "kb" ) ) return ss.str();
	ss << x << "b";
	return ss.str();
}

std::string create_frequency_string( const unsigned x )
{
	std::stringstream ss;
	if( try_creating_unit_string( ss, 2, x, 1000000000, "GHz" ) ) return ss.str();
	if( try_creating_unit_string( ss, 2, x, 1000000,    "MHz" ) ) return ss.str();
	if( try_creating_unit_string( ss, 2, x, 1000,       "kHz" ) ) return ss.str();
	ss << x << "Hz";
	return ss.str();
}


/*
UNREPORTED PROPERTIES:
output << "maxTexture1D=" << deviceProperties.maxTexture1D << std::endl;
output << "maxTexture1DLinear=" << deviceProperties.maxTexture1DLinear << std::endl;
output << "maxTexture2D=" << deviceProperties.maxTexture2D[0] << "," << deviceProperties.maxTexture2D[1] << std::endl;
output << "maxTexture2DLinear=" << deviceProperties.maxTexture2DLinear[0] << "," << deviceProperties.maxTexture2DLinear[1] << "," << deviceProperties.maxTexture2DLinear[2] << std::endl;
output << "maxTexture2DGather=" << deviceProperties.maxTexture2DGather[0] << "," << deviceProperties.maxTexture2DGather[1] << std::endl;
output << "maxTexture3D=" << deviceProperties.maxTexture3D[0] << "," << deviceProperties.maxTexture3D[1] << "," << deviceProperties.maxTexture3D[2] << std::endl;
output << "maxTextureCubemap=" << deviceProperties.maxTextureCubemap << std::endl;
output << "maxTexture1DLayered=" << deviceProperties.maxTexture1DLayered[0] << "," << deviceProperties.maxTexture1DLayered[1] << std::endl;
output << "maxTexture2DLayered=" << deviceProperties.maxTexture2DLayered[0] << "," << deviceProperties.maxTexture2DLayered[1] << "," << deviceProperties.maxTexture2DLayered[2] << std::endl;
output << "maxTextureCubemapLayered=" << deviceProperties.maxTextureCubemapLayered[0] << "," << deviceProperties.maxTextureCubemapLayered[1] << std::endl;
output << "maxSurface1D=" << deviceProperties.maxSurface1D << std::endl;
output << "maxSurface2D=" << deviceProperties.maxSurface2D[0] << "," << deviceProperties.maxSurface2D[1] << std::endl;
output << "maxSurface3D=" << deviceProperties.maxSurface3D[0] << "," << deviceProperties.maxSurface3D[1] << "," << deviceProperties.maxSurface3D[2] << std::endl;
output << "maxSurface1DLayered=" << deviceProperties.maxSurface1DLayered[0] << "," << deviceProperties.maxSurface1DLayered[1] << std::endl;
output << "maxSurface2DLayered=" << deviceProperties.maxSurface2DLayered[0] << "," << deviceProperties.maxSurface2DLayered[1] << "," << deviceProperties.maxSurface2DLayered[2] << std::endl;
output << "maxSurfaceCubemap=" << deviceProperties.maxSurfaceCubemap << std::endl;
output << "maxSurfaceCubemapLayered=" << deviceProperties.maxSurfaceCubemapLayered[0] << "," << deviceProperties.maxSurfaceCubemapLayered[1] << std::endl;
*/

