//----------------------------------------------------------------------------
// This software is in the public domain, furnished "as is", without technical
// support, and with no warranty, express or implied, as to its usefulness for
// any purpose.
//
// array.hpp
// An STL-like structure that resides in video memory.
//
// Author: Scott D. Zuyderduyn, Ph.D. (scott.zuyderduyn@utoronto.ca)
//----------------------------------------------------------------------------

#pragma once
#ifndef ECUDA_ARRAY_HPP
#define ECUDA_ARRAY_HPP

#include <cstddef>
#include <vector>
#include "global.hpp"
#include "memory.hpp"

namespace ecuda {

template<typename T>
class array {

public:
	typedef T value_type;
	typedef std::size_t size_type;
	typedef std::ptrdiff_t difference_type;
	typedef value_type& reference;
	typedef const value_type& const_reference;
	typedef value_type* pointer;
	typedef const value_type* const_pointer;
	//typedef ??? iterator
	//typedef ??? const_iterator;
	//typedef ??? reverse_iterator;
	//typedef ??? const_reverse_iterator;

private:
	size_type n;
	unique_ptr<T[]> deviceMemory; // video card memory

public:
	array( const size_type n=0, const_reference value = T() ) : n(n) {
		if( n ) {
			T* ptr = NULL;
			CUDA_CALL( cudaMalloc( reinterpret_cast<void**>(&ptr), n*sizeof(T) ) );
			std::vector<T> v( n, value );
			CUDA_CALL( cudaMemcpy( ptr, &v[0], n*sizeof(T), cudaMemcpyHostToDevice ) );
			deviceMemory = unique_ptr<T[]>( ptr );
		}
	}
	array( const array<T>& src ) : n(src.n) {
		if( n ) {
			T* ptr = NULL;
			CUDA_CALL( cudaMalloc( reinterpret_cast<void**>(&ptr), n*sizeof(T) ) );
			CUDA_CALL( cudaMemcpy( ptr, src.deviceMemory.get(), n*sizeof(T), cudaMemcpyDeviceToDevice ) );
			deviceMemory = unique_ptr<T[]>( ptr );
		}
	}
	array( const T* sourcePtr, const size_type n=0 ) : n(n) {
		if( n ) {
			T* ptr = NULL;
			CUDA_CALL( cudaMalloc( reinterpret_cast<void**>(&ptr), n*sizeof(T) ) );
			CUDA_CALL( cudaMemcpy( ptr, sourcePtr, n*sizeof(T), cudaMemcpyHostToDevice ) );
			deviceMemory = unique_ptr<T[]>( ptr );
		}
	}

	virtual ~array() {}

	inline reference at( size_type index ) { return deviceMemory[index]; }
	inline reference operator[]( size_type index ) { return deviceMemory[index]; }
	inline const_reference at( size_type index ) const { return deviceMemory[index]; }
	inline const_reference operator[]( size_type index ) const { return deviceMemory[index]; }

	inline reference front() { return *deviceMemory; }
	inline reference back() { return operator[]( size()-1 ); }
	inline const_reference front() const { return *deviceMemory; }
	inline const_reference back() const { return operator[]( size()-1 ); }

	inline size_type size() const { return n; }

};


} // namespace ecuda

#endif